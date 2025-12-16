import { IsString, IsOptional, IsEnum, MaxLength } from 'class-validator';

export enum MediaType {
    IMAGE = 'image',
    VIDEO = 'video',
    NONE = 'none',
}

export class CreatePostDto {
    @IsString()
    @MaxLength(500)
    content: string;

    @IsOptional()
    @IsEnum(MediaType)
    mediaType?: MediaType;

    @IsOptional()
    @IsString()
    mediaUrl?: string;

    @IsOptional()
    @IsString()
    mediaThumbnailUrl?: string;
}
