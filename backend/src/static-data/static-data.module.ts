import { Module, Global } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { StaticDataService } from './static-data.service';
import { Position, MatchType, ReportReason } from './entities';

@Global()
@Module({
    imports: [TypeOrmModule.forFeature([Position, MatchType, ReportReason])],
    providers: [StaticDataService],
    exports: [StaticDataService],
})
export class StaticDataModule { }
