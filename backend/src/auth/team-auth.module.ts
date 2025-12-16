import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TeamAuthController } from './team-auth.controller';
import { TeamAuthService } from './team-auth.service';
import { SupabaseModule } from '../supabase/supabase.module';

@Module({
    imports: [
        SupabaseModule,
        JwtModule.register({
            secret: process.env.JWT_SECRET || 'your-secret-key',
            signOptions: { expiresIn: '7d' },
        }),
    ],
    controllers: [TeamAuthController],
    providers: [TeamAuthService],
    exports: [TeamAuthService],
})
export class TeamAuthModule { }
