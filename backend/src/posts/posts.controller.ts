import {
    Controller,
    Get,
    Post,
    Delete,
    Body,
    Param,
    Query,
    Headers,
    UnauthorizedException,
    Logger,
} from '@nestjs/common';
import { PostsService, PostAuthor } from './posts.service';
import { CreatePostDto, CreateCommentDto } from './dto';
import { JwtService } from '@nestjs/jwt';

@Controller('posts')
export class PostsController {
    private readonly logger = new Logger(PostsController.name);

    constructor(
        private readonly postsService: PostsService,
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

    // Extract context (user or team) from headers
    private extractContext(
        authHeader: string,
        contextType?: string,
        contextId?: string,
    ): PostAuthor {
        const userId = this.extractUserId(authHeader);

        if (contextType === 'team' && contextId) {
            return { type: 'team', id: contextId };
        }

        return { type: 'user', id: userId };
    }

    // GET /posts/feed
    @Get('feed')
    async getFeed(
        @Query('limit') limit?: string,
        @Query('offset') offset?: string,
    ) {
        const posts = await this.postsService.getFeed(
            limit ? parseInt(limit) : 20,
            offset ? parseInt(offset) : 0,
        );
        return { data: posts };
    }

    // GET /posts/user/:userId - Get posts by specific user
    @Get('user/:userId')
    async getUserPosts(
        @Param('userId') userId: string,
        @Query('type') type?: string, // 'media' | 'text' | 'all'
        @Query('limit') limit?: string,
        @Query('offset') offset?: string,
    ) {
        const posts = await this.postsService.getUserPosts(
            userId,
            type || 'all',
            limit ? parseInt(limit) : 20,
            offset ? parseInt(offset) : 0,
        );
        return { data: posts };
    }

    // POST /posts
    @Post()
    async createPost(
        @Headers('authorization') authHeader: string,
        @Headers('x-context-type') contextType: string,
        @Headers('x-context-id') contextId: string,
        @Body() dto: CreatePostDto,
    ) {
        const author = this.extractContext(authHeader, contextType, contextId);
        this.logger.log(`Creating post as ${author.type}: ${author.id}`);
        const post = await this.postsService.createPost(dto, author);
        return { data: post };
    }

    // GET /posts/:id
    @Get(':id')
    async getPost(@Param('id') id: string) {
        const post = await this.postsService.getPost(id);
        return { data: post };
    }

    // DELETE /posts/:id
    @Delete(':id')
    async deletePost(
        @Param('id') id: string,
        @Headers('authorization') authHeader: string,
    ) {
        const userId = this.extractUserId(authHeader);
        return this.postsService.deletePost(id, userId);
    }

    // POST /posts/:id/like
    @Post(':id/like')
    async toggleLike(
        @Param('id') id: string,
        @Headers('authorization') authHeader: string,
    ) {
        const userId = this.extractUserId(authHeader);
        const result = await this.postsService.toggleLike(id, userId);
        return { success: true, ...result };
    }

    // GET /posts/:id/liked
    @Get(':id/liked')
    async isLiked(
        @Param('id') id: string,
        @Headers('authorization') authHeader: string,
    ) {
        const userId = this.extractUserId(authHeader);
        const liked = await this.postsService.isLikedByUser(id, userId);
        return { liked };
    }

    // GET /posts/:id/comments
    @Get(':id/comments')
    async getComments(
        @Param('id') id: string,
        @Query('limit') limit?: string,
        @Query('offset') offset?: string,
    ) {
        const comments = await this.postsService.getComments(
            id,
            limit ? parseInt(limit) : 20,
            offset ? parseInt(offset) : 0,
        );
        return { data: comments };
    }

    // POST /posts/:id/comments
    @Post(':id/comments')
    async addComment(
        @Param('id') id: string,
        @Headers('authorization') authHeader: string,
        @Body() dto: CreateCommentDto,
    ) {
        const userId = this.extractUserId(authHeader);
        const comment = await this.postsService.addComment(id, userId, dto);
        return { data: comment };
    }

    // DELETE /posts/comments/:commentId
    @Delete('comments/:commentId')
    async deleteComment(
        @Param('commentId') commentId: string,
        @Headers('authorization') authHeader: string,
    ) {
        const userId = this.extractUserId(authHeader);
        return this.postsService.deleteComment(commentId, userId);
    }
}
