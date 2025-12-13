import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService implements OnModuleInit {
    private readonly logger = new Logger(SupabaseService.name);
    private _client: SupabaseClient;

    constructor(private configService: ConfigService) {
        const supabaseUrl = this.configService.get<string>('SUPABASE_URL');
        // Use service role key to bypass RLS for backend operations
        const serviceRoleKey = this.configService.get<string>('SUPABASE_SERVICE_ROLE_KEY');
        const anonKey = this.configService.get<string>('SUPABASE_KEY');

        const supabaseKey = serviceRoleKey || anonKey;

        // Log which key is being used
        if (serviceRoleKey) {
            this.logger.log('Using SUPABASE_SERVICE_ROLE_KEY (RLS bypassed)');
        } else if (anonKey) {
            this.logger.warn('Using SUPABASE_KEY (anon key) - RLS will be enforced!');
        }

        if (!supabaseUrl || !supabaseKey) {
            this.logger.warn(
                'Supabase credentials not found. Please set SUPABASE_URL and SUPABASE_KEY in .env',
            );
            return;
        }

        this._client = createClient(supabaseUrl, supabaseKey);
    }

    onModuleInit() {
        if (this._client) {
            this.logger.log('Supabase client initialized successfully');
        } else {
            this.logger.warn('Supabase client not initialized');
        }
    }

    // Public client getter for services to access supabase
    get client(): SupabaseClient {
        return this.getClient();
    }

    getClient(): SupabaseClient {
        if (!this._client) {
            throw new Error('Supabase client is not initialized');
        }
        return this._client;
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
