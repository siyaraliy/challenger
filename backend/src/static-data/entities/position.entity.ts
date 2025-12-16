import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('positions')
export class Position {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ unique: true })
    name: string;

    @Column({ nullable: true })
    description: string;

    @Column({ default: 0 })
    sortOrder: number;
}
