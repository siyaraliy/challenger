import {
    Controller,
    Get,
    Post,
    Body,
    Param,
    Query,
    Headers,
    UnauthorizedException,
    Logger,
} from '@nestjs/common';
import { ChatService, ChatContext } from './chat.service';
import { CreateDirectChatDto, SendMessageDto } from './dto';
import { JwtService } from '@nestjs/jwt';

@Controller('chats')
export class ChatController {
    private readonly logger = new Logger(ChatController.name);

    constructor(
        private readonly chatService: ChatService,
        private readonly jwtService: JwtService,
    ) { }

    // Extract user ID from JWT token
    private extractUserId(authHeader: string): string {
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            throw new UnauthorizedException('Missing or invalid authorization header');
        }
        const token = authHeader.substring(7);
        try {
            const payload = this.jwtService.decode(token) as { sub: string };
            if (!payload?.sub) {
                throw new UnauthorizedException('Invalid token');
            }
            return payload.sub;
        } catch {
            throw new UnauthorizedException('Invalid token');
        }
    }

    // Extract context (user or team)
    private extractContext(
        authHeader: string,
        contextType?: string,
        contextId?: string,
    ): ChatContext {
        const userId = this.extractUserId(authHeader);

        if (contextType === 'team' && contextId) {
            return { type: 'team', id: contextId, userId };
        }

        return { type: 'user', id: userId, userId };
    }

    // GET /chats/my - Get all my chat rooms
    @Get('my')
    async getMyChats(
        @Headers('authorization') authHeader: string,
    ) {
        const userId = this.extractUserId(authHeader);
        const chats = await this.chatService.getMyChats(userId);
        return { data: chats };
    }

    // POST /chats/direct - Create direct chat with a user
    @Post('direct')
    async createDirectChat(
        @Headers('authorization') authHeader: string,
        @Body() dto: CreateDirectChatDto,
    ) {
        const userId = this.extractUserId(authHeader);
        const result = await this.chatService.createDirectChat(userId, dto.userId);
        return { data: result };
    }

    // GET /chats/:roomId - Get room details
    @Get(':roomId')
    async getRoomDetails(
        @Param('roomId') roomId: string,
        @Headers('authorization') authHeader: string,
    ) {
        const userId = this.extractUserId(authHeader);
        const room = await this.chatService.getRoomDetails(roomId, userId);
        return { data: room };
    }

    // GET /chats/:roomId/messages - Get messages
    @Get(':roomId/messages')
    async getMessages(
        @Param('roomId') roomId: string,
        @Headers('authorization') authHeader: string,
        @Query('limit') limit?: string,
        @Query('offset') offset?: string,
    ) {
        const userId = this.extractUserId(authHeader);
        const messages = await this.chatService.getMessages(
            roomId,
            userId,
            limit ? parseInt(limit) : 50,
            offset ? parseInt(offset) : 0,
        );
        return { data: messages };
    }

    // POST /chats/:roomId/messages - Send a message
    @Post(':roomId/messages')
    async sendMessage(
        @Param('roomId') roomId: string,
        @Headers('authorization') authHeader: string,
        @Headers('x-context-type') contextType: string,
        @Headers('x-context-id') contextId: string,
        @Body() dto: SendMessageDto,
    ) {
        const context = this.extractContext(authHeader, contextType, contextId);
        this.logger.log(`Sending message in room ${roomId} as ${context.type}: ${context.id}`);
        const message = await this.chatService.sendMessage(roomId, context, dto);
        return { data: message };
    }

    // GET /chats/:roomId/pending - Get pending join requests
    @Get(':roomId/pending')
    async getPendingRequests(
        @Param('roomId') roomId: string,
        @Headers('authorization') authHeader: string,
    ) {
        const userId = this.extractUserId(authHeader);
        const requests = await this.chatService.getPendingRequests(roomId, userId);
        return { data: requests };
    }

    // POST /chats/:roomId/approve/:participantId - Approve join request
    @Post(':roomId/approve/:participantId')
    async approveJoinRequest(
        @Param('roomId') roomId: string,
        @Param('participantId') participantId: string,
        @Headers('authorization') authHeader: string,
    ) {
        const userId = this.extractUserId(authHeader);
        const result = await this.chatService.approveJoinRequest(roomId, participantId, userId);
        return result;
    }

    // POST /chats/:roomId/reject/:participantId - Reject join request
    @Post(':roomId/reject/:participantId')
    async rejectJoinRequest(
        @Param('roomId') roomId: string,
        @Param('participantId') participantId: string,
        @Headers('authorization') authHeader: string,
    ) {
        const userId = this.extractUserId(authHeader);
        const result = await this.chatService.rejectJoinRequest(roomId, participantId, userId);
        return result;
    }
}
