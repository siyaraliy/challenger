import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { StaticDataService } from './static-data/static-data.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly staticDataService: StaticDataService,
  ) { }

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('positions')
  async getPositions() {
    return {
      source: 'SQLite',
      data: await this.staticDataService.getAllPositions(),
    };
  }

  @Get('match-types')
  async getMatchTypes() {
    return {
      source: 'SQLite',
      data: await this.staticDataService.getAllMatchTypes(),
    };
  }

  @Get('report-reasons')
  async getReportReasons() {
    return {
      source: 'SQLite',
      data: await this.staticDataService.getAllReportReasons(),
    };
  }

  @Get('static-data/all')
  async getAllStaticData() {
    return {
      source: 'SQLite',
      data: await this.staticDataService.getAllData(),
    };
  }
}
