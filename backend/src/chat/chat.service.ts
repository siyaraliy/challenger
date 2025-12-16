import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { SendMessageDto, MessageType } from './dto';

export interface ChatContext {
    type: 'user' | 'team';
    id: string;
    userId: string;
}

@Injectable()
export class ChatService {
    private readonly logger = new Logger(ChatService.name);

    constructor(private readonly supabaseService: SupabaseService) { }

    // Get all chat rooms for a user
    async getMyChats(userId: string) {
        const { data, error } = await this.supabaseService.client
            .from('chat_participants')
            .select(`
                room_id,
                status,
                role,
                chat_rooms (
                    id,
                    type,
                    name,
                    team_id,
                    last_message_at,
                    created_at
                )
            `)
            .eq('participant_id', userId)
            .eq('status', 'approved')
            .order('joined_at', { ascending: false });

        if (error) {
            this.logger.error('Failed to fetch chats:', error);
            throw error;
        }

        // Fetch last message and other participants for each room
        const chatsWithDetails = await Promise.all(
            data.map(async (item) => {
                const room = item.chat_rooms as any;
                if (!room) return null;

                // Get last message
                const { data: lastMessage } = await this.supabaseService.client
                    .from('chat_messages')
                    .select('content, sender_id, created_at')
                    .eq('room_id', room.id)
                    .order('created_at', { ascending: false })
                    .limit(1)
                    .single();

                // Get unread count
                const { count: unreadCount } = await this.supabaseService.client
                    .from('chat_messages')
                    .select('id', { count: 'exact', head: true })
                    .eq('room_id', room.id)
                    .eq('is_read', false)
                    .neq('sender_id', userId);

                // Get other participants for direct chats
                let otherParticipant: { full_name: string | null; avatar_url: string | null } | null = null;
                if (room.type === 'direct') {
                    const { data: participants } = await this.supabaseService.client
                        .from('chat_participants')
                        .select('participant_id')
                        .eq('room_id', room.id)
                        .neq('participant_id', userId)
                        .single();

                    if (participants) {
                        const { data: profile } = await this.supabaseService.client
                            .from('profiles')
                            .select('full_name, avatar_url')
                            .eq('id', participants.participant_id)
                            .single();
                        otherParticipant = profile;
                    }
                }

                return {
                    id: room.id,
                    type: room.type,
                    name: room.type === 'direct' ? otherParticipant?.full_name : room.name,
                    avatarUrl: room.type === 'direct' ? otherParticipant?.avatar_url : null,
                    teamId: room.team_id,
                    lastMessage: lastMessage?.content || null,
                    lastMessageAt: lastMessage?.created_at || room.last_message_at,
                    unreadCount: unreadCount || 0,
                    role: item.role,
                };
            })
        );

        return chatsWithDetails.filter(Boolean);
    }

    // Create or get direct chat between two users
    async createDirectChat(userId: string, targetUserId: string) {
        // Check if target user exists
        const { data: targetUser, error: userError } = await this.supabaseService.client
            .from('profiles')
            .select('id, full_name')
            .eq('id', targetUserId)
            .single();

        if (userError || !targetUser) {
            throw new NotFoundException('User not found');
        }

        // Call the database function to get or create direct chat
        const { data, error } = await this.supabaseService.client
            .rpc('get_or_create_direct_chat', {
                user1_id: userId,
                user2_id: targetUserId,
            });

        if (error) {
            this.logger.error('Failed to create direct chat:', error);
            throw error;
        }

        return { roomId: data };
    }

    // Get messages for a room
    async getMessages(roomId: string, userId: string, limit = 50, offset = 0) {
        // Verify user is a participant
        await this.verifyParticipant(roomId, userId);

        const { data, error } = await this.supabaseService.client
            .from('chat_messages')
            .select(`
                id,
                room_id,
                sender_type,
                sender_id,
                content,
                message_type,
                media_url,
                is_read,
                created_at
            `)
            .eq('room_id', roomId)
            .order('created_at', { ascending: false })
            .range(offset, offset + limit - 1);

        if (error) {
            this.logger.error('Failed to fetch messages:', error);
            throw error;
        }

        // Fetch sender details
        const messagesWithSenders = await Promise.all(
            data.map(async (msg) => {
                const sender = await this.getSenderDetails(msg.sender_type, msg.sender_id);
                return {
                    id: msg.id,
                    roomId: msg.room_id,
                    senderType: msg.sender_type,
                    senderId: msg.sender_id,
                    senderName: sender?.name || 'Unknown',
                    senderAvatar: sender?.avatar || null,
                    content: msg.content,
                    messageType: msg.message_type,
                    mediaUrl: msg.media_url,
                    isRead: msg.is_read,
                    createdAt: msg.created_at,
                    isOwn: msg.sender_id === userId,
                };
            })
        );

        // Mark messages as read
        await this.markMessagesAsRead(roomId, userId);

        return messagesWithSenders.reverse(); // Return in chronological order
    }

    // Send a message
    async sendMessage(roomId: string, context: ChatContext, dto: SendMessageDto) {
        // Verify user is a participant
        await this.verifyParticipant(roomId, context.userId);

        const { data, error } = await this.supabaseService.client
            .from('chat_messages')
            .insert({
                room_id: roomId,
                sender_type: context.type,
                sender_id: context.id,
                content: dto.content,
                message_type: dto.messageType || MessageType.TEXT,
                media_url: dto.mediaUrl || null,
            })
            .select()
            .single();

        if (error) {
            this.logger.error('Failed to send message:', error);
            throw error;
        }

        return {
            id: data.id,
            roomId: data.room_id,
            senderType: data.sender_type,
            senderId: data.sender_id,
            content: data.content,
            messageType: data.message_type,
            mediaUrl: data.media_url,
            isRead: data.is_read,
            createdAt: data.created_at,
            isOwn: true,
        };
    }

    // Get pending join requests for a room (admin only)
    async getPendingRequests(roomId: string, userId: string) {
        // Verify user is admin
        await this.verifyAdmin(roomId, userId);

        const { data, error } = await this.supabaseService.client
            .from('chat_participants')
            .select('id, participant_id, joined_at')
            .eq('room_id', roomId)
            .eq('status', 'pending');

        if (error) {
            this.logger.error('Failed to fetch pending requests:', error);
            throw error;
        }

        // Get user details
        const requestsWithUsers = await Promise.all(
            data.map(async (req) => {
                const { data: profile } = await this.supabaseService.client
                    .from('profiles')
                    .select('full_name, avatar_url')
                    .eq('id', req.participant_id)
                    .single();

                return {
                    id: req.id,
                    participantId: req.participant_id,
                    name: profile?.full_name || 'Unknown',
                    avatarUrl: profile?.avatar_url || null,
                    requestedAt: req.joined_at,
                };
            })
        );

        return requestsWithUsers;
    }

    // Approve join request
    async approveJoinRequest(roomId: string, participantId: string, userId: string) {
        await this.verifyAdmin(roomId, userId);

        const { error } = await this.supabaseService.client
            .from('chat_participants')
            .update({ status: 'approved', updated_at: new Date().toISOString() })
            .eq('room_id', roomId)
            .eq('participant_id', participantId)
            .eq('status', 'pending');

        if (error) {
            this.logger.error('Failed to approve request:', error);
            throw error;
        }

        // Send system message
        await this.sendSystemMessage(roomId, `Yeni üye sohbete katıldı!`);

        return { success: true };
    }

    // Reject join request
    async rejectJoinRequest(roomId: string, participantId: string, userId: string) {
        await this.verifyAdmin(roomId, userId);

        const { error } = await this.supabaseService.client
            .from('chat_participants')
            .update({ status: 'rejected', updated_at: new Date().toISOString() })
            .eq('room_id', roomId)
            .eq('participant_id', participantId)
            .eq('status', 'pending');

        if (error) {
            this.logger.error('Failed to reject request:', error);
            throw error;
        }

        return { success: true };
    }

    // Get room details
    async getRoomDetails(roomId: string, userId: string) {
        const { data: room, error } = await this.supabaseService.client
            .from('chat_rooms')
            .select('*')
            .eq('id', roomId)
            .single();

        if (error || !room) {
            throw new NotFoundException('Chat room not found');
        }

        // Get participants
        const { data: participants } = await this.supabaseService.client
            .from('chat_participants')
            .select('participant_id, role, status')
            .eq('room_id', roomId)
            .eq('status', 'approved');

        // Get current user's role
        const currentParticipant = participants?.find(p => p.participant_id === userId);

        return {
            id: room.id,
            type: room.type,
            name: room.name,
            teamId: room.team_id,
            participantCount: participants?.length || 0,
            isAdmin: currentParticipant?.role === 'admin',
            createdAt: room.created_at,
        };
    }

    // Helper: Verify user is a participant
    private async verifyParticipant(roomId: string, userId: string) {
        const { data, error } = await this.supabaseService.client
            .from('chat_participants')
            .select('status')
            .eq('room_id', roomId)
            .eq('participant_id', userId)
            .single();

        if (error || !data) {
            throw new ForbiddenException('You are not a participant of this chat');
        }

        if (data.status !== 'approved') {
            throw new ForbiddenException('Your participation is pending approval');
        }
    }

    // Helper: Verify user is admin
    private async verifyAdmin(roomId: string, userId: string) {
        const { data, error } = await this.supabaseService.client
            .from('chat_participants')
            .select('role, status')
            .eq('room_id', roomId)
            .eq('participant_id', userId)
            .single();

        if (error || !data || data.status !== 'approved') {
            throw new ForbiddenException('You are not a participant of this chat');
        }

        if (data.role !== 'admin') {
            throw new ForbiddenException('Only admins can perform this action');
        }
    }

    // Helper: Get sender details
    private async getSenderDetails(senderType: string, senderId: string) {
        if (senderType === 'user') {
            const { data } = await this.supabaseService.client
                .from('profiles')
                .select('full_name, avatar_url')
                .eq('id', senderId)
                .single();
            return data ? { name: data.full_name, avatar: data.avatar_url } : null;
        } else {
            const { data } = await this.supabaseService.client
                .from('teams')
                .select('name, logo_url')
                .eq('id', senderId)
                .single();
            return data ? { name: data.name, avatar: data.logo_url } : null;
        }
    }

    // Helper: Mark messages as read
    private async markMessagesAsRead(roomId: string, userId: string) {
        await this.supabaseService.client
            .from('chat_messages')
            .update({ is_read: true })
            .eq('room_id', roomId)
            .eq('is_read', false)
            .neq('sender_id', userId);
    }

    // Helper: Send system message
    private async sendSystemMessage(roomId: string, content: string) {
        await this.supabaseService.client
            .from('chat_messages')
            .insert({
                room_id: roomId,
                sender_type: 'user',
                sender_id: '00000000-0000-0000-0000-000000000000', // System ID
                content,
                message_type: MessageType.SYSTEM,
            });
    }
}
