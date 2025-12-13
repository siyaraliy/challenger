import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Position, MatchType, ReportReason } from './entities';

@Injectable()
export class StaticDataService implements OnModuleInit {
    private readonly logger = new Logger(StaticDataService.name);

    constructor(
        @InjectRepository(Position)
        private positionRepo: Repository<Position>,
        @InjectRepository(MatchType)
        private matchTypeRepo: Repository<MatchType>,
        @InjectRepository(ReportReason)
        private reportReasonRepo: Repository<ReportReason>,
    ) { }

    async onModuleInit() {
        await this.seedData();
    }

    private async seedData() {
        // Seed Positions
        const positionCount = await this.positionRepo.count();
        if (positionCount === 0) {
            this.logger.log('Seeding positions...');
            await this.positionRepo.save([
                { name: 'Kaleci', description: 'Kaleyi koruyan oyuncu', sortOrder: 1 },
                { name: 'Defans', description: 'Savunma oyuncusu', sortOrder: 2 },
                { name: 'Orta Saha', description: 'Orta alan oyuncusu', sortOrder: 3 },
                { name: 'Forvet', description: 'Hücum oyuncusu', sortOrder: 4 },
            ]);
        }

        // Seed Match Types
        const matchTypeCount = await this.matchTypeRepo.count();
        if (matchTypeCount === 0) {
            this.logger.log('Seeding match types...');
            await this.matchTypeRepo.save([
                { name: '5v5', playerCount: 5, description: '5 kişilik maç', sortOrder: 1 },
                { name: '6v6', playerCount: 6, description: '6 kişilik maç', sortOrder: 2 },
                { name: '7v7', playerCount: 7, description: '7 kişilik maç', sortOrder: 3 },
                { name: '11v11', playerCount: 11, description: 'Tam saha maç', sortOrder: 4 },
            ]);
        }

        // Seed Report Reasons
        const reportReasonCount = await this.reportReasonRepo.count();
        if (reportReasonCount === 0) {
            this.logger.log('Seeding report reasons...');
            await this.reportReasonRepo.save([
                { code: 'spam', name: 'Spam', description: 'İstenmeyen veya tekrarlanan içerik', sortOrder: 1 },
                { code: 'harassment', name: 'Taciz/Hakaret', description: 'Kişisel saldırı veya hakaret', sortOrder: 2 },
                { code: 'inappropriate', name: 'Uygunsuz İçerik', description: 'Müstehcen veya şiddet içeren içerik', sortOrder: 3 },
                { code: 'fake', name: 'Sahte Hesap', description: 'Başka birini taklit eden hesap', sortOrder: 4 },
                { code: 'other', name: 'Diğer', description: 'Diğer nedenler', sortOrder: 5 },
            ]);
        }

        this.logger.log('Static data ready (SQLite)');
    }

    // Positions
    async getAllPositions(): Promise<Position[]> {
        return this.positionRepo.find({ order: { sortOrder: 'ASC' } });
    }

    async getPositionById(id: number): Promise<Position | null> {
        return this.positionRepo.findOne({ where: { id } });
    }

    // Match Types
    async getAllMatchTypes(): Promise<MatchType[]> {
        return this.matchTypeRepo.find({ order: { sortOrder: 'ASC' } });
    }

    async getMatchTypeById(id: number): Promise<MatchType | null> {
        return this.matchTypeRepo.findOne({ where: { id } });
    }

    // Report Reasons
    async getAllReportReasons(): Promise<ReportReason[]> {
        return this.reportReasonRepo.find({ where: { isActive: true }, order: { sortOrder: 'ASC' } });
    }

    async getReportReasonById(id: number): Promise<ReportReason | null> {
        return this.reportReasonRepo.findOne({ where: { id } });
    }

    async getReportReasonByCode(code: string): Promise<ReportReason | null> {
        return this.reportReasonRepo.findOne({ where: { code } });
    }

    // Complete Data
    async getAllData() {
        const [positions, matchTypes, reportReasons] = await Promise.all([
            this.getAllPositions(),
            this.getAllMatchTypes(),
            this.getAllReportReasons(),
        ]);
        return { positions, matchTypes, reportReasons };
    }
}
