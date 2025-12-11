import { Controller, Get, Query } from '@nestjs/common';
import { AppService } from './app.service';
import { RedisService } from './redis/redis.service';
import { StaticDataService } from './static-data/static-data.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly redisService: RedisService,
    private readonly staticDataService: StaticDataService,
  ) { }

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  // Redis Test Endpoints
  @Get('redis/set')
  async redisSet(
    @Query('key') key: string,
    @Query('value') value: string,
    @Query('ttl') ttl?: string,
  ) {
    const ttlSeconds = ttl ? parseInt(ttl, 10) : undefined;
    await this.redisService.set(key, value, ttlSeconds);
    return {
      success: true,
      message: `Key "${key}" set with value "${value}"${ttl ? ` (TTL: ${ttl}s)` : ''}`,
    };
  }

  @Get('redis/get')
  async redisGet(@Query('key') key: string) {
    const value = await this.redisService.get(key);
    const ttl = await this.redisService.getTTL(key);
    return {
      key,
      value,
      ttl: ttl > 0 ? `${ttl} seconds remaining` : 'No TTL',
      exists: value !== null,
    };
  }

  @Get('redis/delete')
  async redisDelete(@Query('key') key: string) {
    const deleted = await this.redisService.del(key);
    return {
      success: deleted > 0,
      message: deleted > 0 ? `Key "${key}" deleted` : `Key "${key}" not found`,
    };
  }

  // Static Data Test Endpoints
  @Get('static/positions')
  getPositions() {
    return {
      data: this.staticDataService.getAllPositions(),
    };
  }

  @Get('static/match-types')
  getMatchTypes() {
    return {
      data: this.staticDataService.getAllMatchTypes(),
    };
  }

  @Get('static/report-reasons')
  getReportReasons() {
    return {
      data: this.staticDataService.getAllReportReasons(),
    };
  }

  @Get('static/all')
  getAllStaticData() {
    return {
      data: this.staticDataService.getAllData(),
    };
  }
}
