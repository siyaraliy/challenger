import { IsString, IsOptional, IsEnum, MaxLength } from 'class-validator';

export enum MessageType {
    TEXT = 'text',
    IMAGE = 'image',
    VIDEO = 'video',
    SYSTEM = 'system',
}

export class CreateDirectChatDto {
    @IsString()
    userId: string;
}

export class SendMessageDto {
    @IsString()
    @MaxLength(2000)
    content: string;

    @IsOptional()
    @IsEnum(MessageType)
    messageType?: MessageType;

    @IsOptional()
    @IsString()
    mediaUrl?: string;
}

export class GetMessagesQueryDto {
    @IsOptional()
    @IsString()
    limit?: string;

    @IsOptional()
    @IsString()
    offset?: string;
}
