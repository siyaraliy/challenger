import { IsEmail, IsNotEmpty, MinLength, IsUUID } from 'class-validator';

export class RegisterTeamCredentialsDto {
    @IsUUID()
    @IsNotEmpty()
    teamId: string;

    @IsEmail()
    @IsNotEmpty()
    email: string;

    @IsNotEmpty()
    @MinLength(6)
    password: string;
}
