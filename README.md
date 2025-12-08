# CHALLENGER

**Version:** 1.0.0 (Master Release)  
**Date:** 02.12.2025  
**Standard:** IEEE Std 830-1998

---

## 1. INTRODUCTION

### 1.1 Purpose
This document defines the technical and functional requirements of the Challenger mobile platform. The purpose is to establish standards for a system where football teams can compete, players can socialize, and all organizational processes (challenges, match scheduling, team finding) are managed through an integrated communication infrastructure.

### 1.2 Scope
Challenger is a social network that digitizes the amateur football ecosystem.

**Key Capabilities:**
*   **Social Network:** Individual and team profiles, media-rich news feed.
*   **Negotiated Competition:** Teams challenging each other and deciding match details (pitch, time) in in-app Negotiation Rooms.
*   **Communication Network:** Individual messaging (DM) and Team-Player transfer negotiations.
*   **Scoring:** Participation-focused scoring algorithm based on match results.

### 1.3 Definitions
*   **Negotiation Room:** A specialized chat area automatically created by the system when a challenge is accepted, accessible only to the two team captains to clarify match details.
*   **System Message:** Informational logs appearing in the chat flow representing an action taken (e.g., "Match time updated"), not text written by users.

---

## 2. OVERALL DESCRIPTION

### 2.1 Product Perspective
The system is a Client-Server architecture based on real-time data flow.

*   **Client (Mobile):** Android/iOS application developed with Google Flutter framework, operating on an "Offline-First" principle.
*   **Server (Backend):** RESTful API and Socket.IO (WebSocket) services running on NestJS.
*   **Data Management:**
    *   **PostgreSQL:** User, Team, Match, and Relational data.
    *   **Redis:** Instant message queue, cache, and Leaderboard.
    *   **Object Storage (AWS S3):** Media files.

### 2.2 Product Functions
*   **Identity Management:** Secure login via Email, Google, Apple.
*   **Advanced Challenge:** Offer -> Accept -> Negotiate -> Confirm -> Result cycle.
*   **Integrated Messaging (Chat Core):**
    *   Individual Chats.
    *   Team Applications (From Player to Team Managers).
    *   Match Negotiations (From Team to Team).
*   **Feed & Discover:** Location-based opponent/player search and social content sharing.

### 2.3 User Characteristics
*   **Captain:** Messages on behalf of the team, has authority to change match time/location in the negotiation room.
*   **Player:** Searches for teams, messages, creates content.
*   **Admin:** Audits reported messages and content.

---

## 3. SPECIFIC REQUIREMENTS

### 3.1 Functional Requirements

#### FR-1: Communication & Messaging System
*   **FR-1.1 (Chat Types):** The system must support three types of chats: (1) Individual DM, (2) Team Application (Group message), (3) Match Negotiation.
*   **FR-1.2 (System Messages):** When a captain updates the match time or pitch in the negotiation room, a non-clickable system log must appear in the chat window (e.g., "Captain A updated the time to 21:00").
*   **FR-1.3 (Offline Queue):** Messages sent while the user is offline must be queued in the local database (Local DB) and automatically transmitted when connection is restored.
*   **FR-1.4 (Moderation):** Users must be able to use the "Report" option by long-pressing on disturbing messages.

#### FR-2: Challenge & Negotiation Cycle
*   **FR-2.1 (Initiation):** When a challenge request is sent, the status becomes `PENDING`.
*   **FR-2.2 (Channel Opening):** When the request is accepted (`ACCEPTED`), the system creates a unique `chat_room_id` and adds both captains to this room.
*   **FR-2.3 (Agreement):** A "Match Summary" card (Sticky Header) is located at the top of the chat screen. Captains use the "Edit" button on this card to change parameters (Pitch, Time).
*   **FR-2.4 (Finalization):** When both parties confirm the final details, the match status becomes `SCHEDULED` and is added to the calendar.

#### FR-3: Team & Player Interaction
*   **FR-3.1 (Team Search):** Players can search using the "Teams Looking for Players" filter and start a direct message ("Recruitment Chat") via the team profile.
*   **FR-3.2 (Scoring):** After the match result is entered, a "Match Completion Score" is processed for both teams, regardless of the winner/loser.

### 3.2 Interface Requirements (UI/UX)
*   **Technology:** Flutter (Material 3 & Cupertino).
*   **Chat Interface:** WhatsApp-like fluid list structure. Message alignment (right/left), read receipts (double tick), typing animation.
*   **Map:** In-app Google Maps integration for pitch selection during negotiation.

### 3.3 Performance Requirements
*   **Latency:** Message delivery < 100ms.
*   **Rendering:** 60 FPS performance while scrolling the chat list (Flutter `ListView.builder` optimization).
*   **Media:** Images sent within chat must be optimized (thumbnail) and served via AWS CloudFront.

### 3.4 Database Schema (Summary)
This structure manages relational data and messaging data in a hybrid way:

*   **Table: `challenges`**
    *   `id`, `challenger_team_id`, `opponent_team_id`, `status`, `negotiation_room_id` (FK).
*   **Table: `chat_rooms`**
    *   `id`, `type` (DM, NEGOTIATION, RECRUIT), `meta_data` (Related match or team ID).
*   **Table: `messages`**
    *   `id`, `room_id`, `sender_id`, `content`, `is_system_message` (Boolean), `created_at`.
*   **Table: `users` / `teams`**
    *   Standard profile data.

---

## 4. TECH STACK

*   **Mobile:** Flutter, Dart, Bloc/Cubit, Hive (Local DB)
*   **Backend:** NestJS, TypeScript, Socket.IO
*   **Database:** PostgreSQL, Redis
*   **DevOps:** Docker, Docker Compose
*   **Cloud:** AWS S3 (Storage), AWS CloudFront (CDN)

---

## 5. RISKS AND CONSTRAINTS

*   **Risk:** Excessive growth of chat data over time.
    *   **Mitigation:** Automatic archiving of messages older than 1 year (Cold Storage).
*   **Constraint:** The negotiation room must switch to "Read-Only" mode 24 hours after the match is completed.