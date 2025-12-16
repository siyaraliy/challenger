import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('report_reasons')
export class ReportReason {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ unique: true })
    code: string;

    @Column()
    name: string;

    @Column({ nullable: true })
    description: string;

    @Column({ default: true })
    isActive: boolean;

    @Column({ default: 0 })
    sortOrder: number;
}
