import { IsString, MaxLength } from 'class-validator';

export class CreateCommentDto {
    @IsString()
    @MaxLength(200)
    content: string;
}
