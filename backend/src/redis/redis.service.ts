import { Injectable, OnModuleDestroy, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleDestroy {
    private readonly logger = new Logger(RedisService.name);
    private readonly client: Redis;

    constructor(private configService: ConfigService) {
        const redisHost = this.configService.get<string>('REDIS_HOST', 'localhost');
        const redisPort = this.configService.get<number>('REDIS_PORT', 6379);

        this.client = new Redis({
            host: redisHost,
            port: redisPort,
            retryStrategy: (times) => {
                const delay = Math.min(times * 50, 2000);
                return delay;
            },
        });

        this.client.on('connect', () => {
            this.logger.log('Redis connected successfully');
        });

        this.client.on('error', (err) => {
            this.logger.error('Redis connection error:', err);
        });
    }

    getClient(): Redis {
        return this.client;
    }

    // Helper methods for common operations
    async set(key: string, value: string, ttlSeconds?: number): Promise<void> {
        if (ttlSeconds) {
            await this.client.setex(key, ttlSeconds, value);
        } else {
            await this.client.set(key, value);
        }
    }

    async get(key: string): Promise<string | null> {
        return await this.client.get(key);
    }

    async del(key: string): Promise<number> {
        return await this.client.del(key);
    }

    async exists(key: string): Promise<boolean> {
        const result = await this.client.exists(key);
        return result === 1;
    }

    async getTTL(key: string): Promise<number> {
        return await this.client.ttl(key);
    }

    async increment(key: string): Promise<number> {
        return await this.client.incr(key);
    }

    async decrement(key: string): Promise<number> {
        return await this.client.decr(key);
    }

    onModuleDestroy() {
        this.client.disconnect();
        this.logger.log('Redis disconnected');
    }
}
