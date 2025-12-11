import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService implements OnModuleInit {
    private readonly logger = new Logger(SupabaseService.name);
    private client: SupabaseClient;

    constructor(private configService: ConfigService) {
        const supabaseUrl = this.configService.get<string>('SUPABASE_URL');
        const supabaseKey = this.configService.get<string>('SUPABASE_KEY');

        if (!supabaseUrl || !supabaseKey) {
            this.logger.warn(
                'Supabase credentials not found. Please set SUPABASE_URL and SUPABASE_KEY in .env',
            );
            return;
        }

        this.client = createClient(supabaseUrl, supabaseKey);
    }

    onModuleInit() {
        if (this.client) {
            this.logger.log('Supabase client initialized successfully');
        } else {
            this.logger.warn('Supabase client not initialized');
        }
    }

    getClient(): SupabaseClient {
        if (!this.client) {
            throw new Error('Supabase client is not initialized');
        }
        return this.client;
    }

    // Helper method for users table
    get users() {
        return this.getClient().from('users');
    }

    // Helper method for teams table
    get teams() {
        return this.getClient().from('teams');
    }

    // Helper method for messages table
    get messages() {
        return this.getClient().from('messages');
    }

    // Helper method for challenges table
    get challenges() {
        return this.getClient().from('challenges');
    }

    // Generic method for any table
    from(tableName: string) {
        return this.getClient().from(tableName);
    }

    // Storage methods
    storage(bucketName: string) {
        return this.getClient().storage.from(bucketName);
    }
}
