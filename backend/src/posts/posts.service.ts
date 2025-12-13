import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { CreatePostDto, CreateCommentDto, MediaType } from './dto';

export interface PostAuthor {
    type: 'user' | 'team';
    id: string;
}

@Injectable()
export class PostsService {
    private readonly logger = new Logger(PostsService.name);

    constructor(private readonly supabaseService: SupabaseService) { }

    // Get feed posts (all posts, newest first)
    async getFeed(limit = 20, offset = 0) {
        const { data, error } = await this.supabaseService.client
            .from('posts')
            .select(`
        id,
        author_type,
        author_id,
        content,
        media_type,
        media_url,
        media_thumbnail_url,
        likes_count,
        comments_count,
        created_at
      `)
            .order('created_at', { ascending: false })
            .range(offset, offset + limit - 1);

        if (error) {
            this.logger.error('Failed to fetch feed:', error);
            throw error;
        }

        // Fetch author details for each post
        const postsWithAuthors = await Promise.all(
            data.map(async (post) => {
                const author = await this.getAuthorDetails(post.author_type, post.author_id);
                return {
                    id: post.id,
                    authorType: post.author_type,
                    authorId: post.author_id,
                    authorName: author?.name || 'Unknown',
                    authorAvatar: author?.avatar || null,
                    content: post.content,
                    mediaType: post.media_type,
                    mediaUrl: post.media_url,
                    mediaThumbnailUrl: post.media_thumbnail_url,
                    likesCount: post.likes_count,
                    commentsCount: post.comments_count,
                    createdAt: post.created_at,
                };
            })
        );

        return postsWithAuthors;
    }

    // Get posts by specific user
    async getUserPosts(userId: string, type: string, limit = 20, offset = 0) {
        let query = this.supabaseService.client
            .from('posts')
            .select(`
                id,
                author_type,
                author_id,
                content,
                media_type,
                media_url,
                media_thumbnail_url,
                likes_count,
                comments_count,
                created_at
            `)
            .eq('author_type', 'user')
            .eq('author_id', userId)
            .order('created_at', { ascending: false });

        // Filter by type
        if (type === 'media') {
            query = query.in('media_type', ['image', 'video']);
        } else if (type === 'text') {
            query = query.eq('media_type', 'none');
        }

        const { data, error } = await query.range(offset, offset + limit - 1);

        if (error) {
            this.logger.error('Failed to fetch user posts:', error);
            throw error;
        }

        // Fetch author details
        const author = await this.getAuthorDetails('user', userId);

        return data.map((post) => ({
            id: post.id,
            authorType: post.author_type,
            authorId: post.author_id,
            authorName: author?.name || 'Unknown',
            authorAvatar: author?.avatar || null,
            content: post.content,
            mediaType: post.media_type,
            mediaUrl: post.media_url,
            mediaThumbnailUrl: post.media_thumbnail_url,
            likesCount: post.likes_count,
            commentsCount: post.comments_count,
            createdAt: post.created_at,
        }));
    }

    // Get author details (user or team)
    private async getAuthorDetails(authorType: string, authorId: string) {
        if (authorType === 'user') {
            const { data } = await this.supabaseService.client
                .from('profiles')
                .select('full_name, avatar_url')
                .eq('id', authorId)
                .single();
            return data ? { name: data.full_name, avatar: data.avatar_url } : null;
        } else {
            const { data } = await this.supabaseService.client
                .from('teams')
                .select('name, logo_url')
                .eq('id', authorId)
                .single();
            return data ? { name: data.name, avatar: data.logo_url } : null;
        }
    }

    // Create a new post
    async createPost(dto: CreatePostDto, author: PostAuthor) {
        const { data, error } = await this.supabaseService.client
            .from('posts')
            .insert({
                author_type: author.type,
                author_id: author.id,
                content: dto.content,
                media_type: dto.mediaType || MediaType.NONE,
                media_url: dto.mediaUrl || null,
                media_thumbnail_url: dto.mediaThumbnailUrl || null,
            })
            .select()
            .single();

        if (error) {
            this.logger.error('Failed to create post:', error);
            throw error;
        }

        return data;
    }

    // Get single post
    async getPost(postId: string) {
        const { data, error } = await this.supabaseService.client
            .from('posts')
            .select('*')
            .eq('id', postId)
            .single();

        if (error || !data) {
            throw new NotFoundException('Post not found');
        }

        return data;
    }

    // Delete post
    async deletePost(postId: string, userId: string) {
        const post = await this.getPost(postId);

        // Check ownership
        if (post.author_type === 'user' && post.author_id !== userId) {
            throw new ForbiddenException('You can only delete your own posts');
        }

        const { error } = await this.supabaseService.client
            .from('posts')
            .delete()
            .eq('id', postId);

        if (error) {
            this.logger.error('Failed to delete post:', error);
            throw error;
        }

        return { success: true };
    }

    // Toggle like
    async toggleLike(postId: string, userId: string) {
        // Check if already liked
        const { data: existingLike } = await this.supabaseService.client
            .from('post_likes')
            .select('post_id')
            .eq('post_id', postId)
            .eq('user_id', userId)
            .single();

        if (existingLike) {
            // Unlike
            await this.supabaseService.client
                .from('post_likes')
                .delete()
                .eq('post_id', postId)
                .eq('user_id', userId);
            return { liked: false };
        } else {
            // Like
            await this.supabaseService.client
                .from('post_likes')
                .insert({ post_id: postId, user_id: userId });
            return { liked: true };
        }
    }

    // Check if user liked a post
    async isLikedByUser(postId: string, userId: string): Promise<boolean> {
        const { data } = await this.supabaseService.client
            .from('post_likes')
            .select('post_id')
            .eq('post_id', postId)
            .eq('user_id', userId)
            .single();
        return !!data;
    }

    // Get comments for a post
    async getComments(postId: string, limit = 20, offset = 0) {
        const { data, error } = await this.supabaseService.client
            .from('post_comments')
            .select(`
        id,
        user_id,
        content,
        created_at
      `)
            .eq('post_id', postId)
            .order('created_at', { ascending: true })
            .range(offset, offset + limit - 1);

        if (error) {
            this.logger.error('Failed to fetch comments:', error);
            throw error;
        }

        // Fetch user details for each comment
        const commentsWithUsers = await Promise.all(
            data.map(async (comment) => {
                const { data: user } = await this.supabaseService.client
                    .from('profiles')
                    .select('full_name, avatar_url')
                    .eq('id', comment.user_id)
                    .single();

                return {
                    id: comment.id,
                    userId: comment.user_id,
                    userName: user?.full_name || 'Unknown',
                    userAvatar: user?.avatar_url || null,
                    content: comment.content,
                    createdAt: comment.created_at,
                };
            })
        );

        return commentsWithUsers;
    }

    // Add comment
    async addComment(postId: string, userId: string, dto: CreateCommentDto) {
        const { data, error } = await this.supabaseService.client
            .from('post_comments')
            .insert({
                post_id: postId,
                user_id: userId,
                content: dto.content,
            })
            .select()
            .single();

        if (error) {
            this.logger.error('Failed to add comment:', error);
            throw error;
        }

        return data;
    }

    // Delete comment
    async deleteComment(commentId: string, userId: string) {
        const { data: comment } = await this.supabaseService.client
            .from('post_comments')
            .select('user_id')
            .eq('id', commentId)
            .single();

        if (!comment) {
            throw new NotFoundException('Comment not found');
        }

        if (comment.user_id !== userId) {
            throw new ForbiddenException('You can only delete your own comments');
        }

        const { error } = await this.supabaseService.client
            .from('post_comments')
            .delete()
            .eq('id', commentId);

        if (error) throw error;

        return { success: true };
    }
}
