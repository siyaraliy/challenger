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
  getPositions() {
    return {
      data: this.staticDataService.getAllPositions(),
    };
  }

  @Get('match-types')
  getMatchTypes() {
    return {
      data: this.staticDataService.getAllMatchTypes(),
    };
  }

  @Get('report-reasons')
  getReportReasons() {
    return {
      data: this.staticDataService.getAllReportReasons(),
    };
  }

  @Get('static-data/all')
  getAllStaticData() {
    return {
      data: this.staticDataService.getAllData(),
    };
  }
}
