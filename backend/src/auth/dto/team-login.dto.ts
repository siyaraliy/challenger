import { IsEmail, IsNotEmpty } from 'class-validator';

export class TeamLoginDto {
    @IsEmail()
    @IsNotEmpty()
    email: string;

    @IsNotEmpty()
    password: string;
}
