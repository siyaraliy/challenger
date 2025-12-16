# Redis Module

Bu modül, NestJS uygulamasında Redis entegrasyonunu sağlar.

## Kurulum

Redis servisi otomatik olarak tüm uygulamada kullanılabilir durumdadır (`@Global` decorator sayesinde).

## Ortam Değişkenleri

`.env` dosyanıza aşağıdaki değişkenleri ekleyin:

```env
REDIS_HOST=localhost
REDIS_PORT=6379
```

## Kullanım

Herhangi bir serviste Redis'i kullanmak için:

```typescript
import { Injectable } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';

@Injectable()
export class YourService {
  constructor(private readonly redisService: RedisService) {}

  async exampleUsage() {
    // Set a value with TTL (Time To Live)
    await this.redisService.set('challenge:user:123', 'data', 3600);

    // Get a value
    const value = await this.redisService.get('challenge:user:123');

    // Check if key exists
    const exists = await this.redisService.exists('challenge:user:123');

    // Get TTL of a key
    const ttl = await this.redisService.getTTL('challenge:user:123');

    // Increment/Decrement
    await this.redisService.increment('counter:challenges');
    await this.redisService.decrement('counter:challenges');

    // Delete a key
    await this.redisService.del('challenge:user:123');

    // Advanced usage: Get raw client
    const redisClient = this.redisService.getClient();
    await redisClient.lpush('list:key', 'value');
  }
}
```

## Özellikler

- ✅ Otomatik yeniden bağlanma stratejisi
- ✅ Bağlantı durumu loglama
- ✅ Yaygın Redis operasyonları için helper metodlar
- ✅ TTL (Time To Live) desteği
- ✅ Modül kapatıldığında otomatik disconnect

## Docker ile Kullanım

Projedeki `docker-compose.yml` Redis servisini içermektedir:

```bash
docker-compose up -d redis
```

## Test

Redis bağlantısını test etmek için:

```bash
npm run start:dev
```

Logları kontrol edin, "Redis connected successfully" mesajını görmelisiniz.
