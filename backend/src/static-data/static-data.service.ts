import { Injectable } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

export interface Position {
    id: string;
    name: string;
    abbreviation: string;
}

export interface MatchType {
    id: string;
    name: string;
    playerCount: number;
}

export interface ReportReason {
    id: string;
    name: string;
    severity: 'low' | 'medium' | 'high';
}

export interface StaticData {
    positions: Position[];
    matchTypes: MatchType[];
    reportReasons: ReportReason[];
}

@Injectable()
export class StaticDataService {
    private readonly data: StaticData;

    constructor() {
        const filePath = path.join(__dirname, '../data/constants.json');
        const fileContent = fs.readFileSync(filePath, 'utf-8');
        this.data = JSON.parse(fileContent);
    }

    // Positions
    getAllPositions(): Position[] {
        return this.data.positions;
    }

    getPositionById(id: string): Position | undefined {
        return this.data.positions.find((p) => p.id === id);
    }

    // Match Types
    getAllMatchTypes(): MatchType[] {
        return this.data.matchTypes;
    }

    getMatchTypeById(id: string): MatchType | undefined {
        return this.data.matchTypes.find((m) => m.id === id);
    }

    // Report Reasons
    getAllReportReasons(): ReportReason[] {
        return this.data.reportReasons;
    }

    getReportReasonById(id: string): ReportReason | undefined {
        return this.data.reportReasons.find((r) => r.id === id);
    }

    getReportReasonsBySeverity(
        severity: 'low' | 'medium' | 'high',
    ): ReportReason[] {
        return this.data.reportReasons.filter((r) => r.severity === severity);
    }

    // Complete Data (for debugging/admin)
    getAllData(): StaticData {
        return this.data;
    }
}
