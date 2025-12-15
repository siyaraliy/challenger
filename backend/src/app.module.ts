import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SupabaseModule } from './supabase/supabase.module';
import { StaticDataModule } from './static-data/static-data.module';
import { TeamAuthModule } from './auth/team-auth.module';
import { PostsModule } from './posts/posts.module';
import { InvitationsModule } from './invitations/invitations.module';
import { Position, MatchType, ReportReason } from './static-data/entities';

@Module({
  imports: [
    ConfigModule.forRoot(),
    // SQLite for static data
    TypeOrmModule.forRoot({
      type: 'better-sqlite3',
      database: 'static.db',
      entities: [Position, MatchType, ReportReason],
      synchronize: true, // Auto-create tables
    }),
    SupabaseModule,
    StaticDataModule,
    TeamAuthModule,
    PostsModule,
    InvitationsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }

