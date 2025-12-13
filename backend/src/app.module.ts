import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SupabaseModule } from './supabase/supabase.module';
import { StaticDataModule } from './static-data/static-data.module';
import { TeamAuthModule } from './auth/team-auth.module';

@Module({
  imports: [
    ConfigModule.forRoot(),
    SupabaseModule,
    StaticDataModule,
    TeamAuthModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }
