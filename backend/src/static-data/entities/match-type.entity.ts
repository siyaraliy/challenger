import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('match_types')
export class MatchType {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ unique: true })
    name: string;

    @Column()
    playerCount: number;

    @Column({ nullable: true })
    description: string;

    @Column({ default: 0 })
    sortOrder: number;
}
