# EXAMS — DATABASE BASELINE

## 1. Database Overview
- **Database Engine:** PostgreSQL (Configured as PostgreSQL 17 in `docker-compose.yml`)
- **ORM / Client:** Prisma ORM (`@prisma/client: ^6.5.0`, CLI: `prisma: ^6.5.0`)
- **Schema Location:** `backend/prisma/schema.prisma`
- **Migration Status:** **NO MIGRATIONS EXIST.** There is no `backend/prisma/migrations/` directory. Schema synchronization has relied on `prisma db push` (`npm run prisma:push`), which is dangerous for production due to lack of rollback history and risk of unprompted schema alterations.

---

## 2. Enums Inventory

1. `Role`: `STUDENT`, `FACULTY`, `ADMIN`
2. `DutyRole`: `INVIGILATOR`, `LEAD`
3. `DutyStatus`: `CONFIRMED`, `PENDING_SWAP`
4. `DutySwapStatus`: `PENDING`, `APPROVED`, `REJECTED`
5. `ActivityType`: `BUNDLE_SCANNED`, `ATTENDANCE_MARKED`, `SUPPLIES_REQUESTED`, `WASHROOM_STARTED`, `WASHROOM_ENDED`, `SOS_REQUESTED`, `REPORT_SUBMITTED`
6. `WashroomStatus`: `ACTIVE`, `WARNING`, `VIOLATION`, `RETURNED`
7. `SOSStatus`: `PENDING`, `RESOLVED`

---

## 3. Models Inventory

### 1. `User` (mapped to `users`)
- **Purpose:** Core authentication credential entity.
- **Primary Key:** `id` (Int, Autoincrement)
- **Key Fields:** `email` (String, Unique), `password` (String, bcrypt hash), `role` (`Role`)
- **Relations:** 1-to-1 optional with `Student`, 1-to-1 optional with `Faculty`

### 2. `Student` (mapped to `students`)
- **Purpose:** Profile record for student accounts.
- **Primary Key:** `id` (Int, Autoincrement)
- **Key Fields:** `userId` (Int, Unique, Foreign Key → `users.id` ON DELETE CASCADE), `name` (String?, optional), `rollNumber` (String?, Unique), `department` (String?, optional)
- **Relations:** Belongs to `User`, 1-to-many with `SeatingAllocation`

### 3. `Faculty` (mapped to `faculty`)
- **Purpose:** Profile record for teaching/invigilation staff.
- **Primary Key:** `id` (Int, Autoincrement)
- **Key Fields:** `userId` (Int, Unique, Foreign Key → `users.id` ON DELETE CASCADE), `name` (String?, optional), `department` (String?, optional)
- **Relations:** Belongs to `User`, 1-to-many with `Duty`, `DutySwapRequest`, `BundleScanLog`, `Attendance`, `SupplyRequest`, `WashroomLog`, `SOSRequest`, `PostExamReport`, `ActivityLog`

### 4. `Exam` (mapped to `exams`)
- **Purpose:** Exam session definition.
- **Primary Key:** `id` (Int, Autoincrement)
- **Key Fields:** `subject` (String), `examDate` (DateTime, mapped to `exam_date`), `examTime` (String, mapped to `exam_time`, e.g. "09:00 AM - 12:00 PM")
- **Relations:** 1-to-many with `Bundle`, `SeatingAllocation`, `Duty`

### 5. `SeatingAllocation` (mapped to `seating_allocations`)
- **Purpose:** Maps student to exam, room, and seat number.
- **Primary Key:** Composite `@@id([studentId, examId])`
- **Key Fields:** `studentId` (Int, FK → `students.id`), `examId` (Int, FK → `exams.id`), `room` (String), `seat` (String)
- **Indexes:** `@@index([examId])`

### 6. `Duty` (mapped to `duties`)
- **Purpose:** Faculty invigilation assignment.
- **Primary Key:** `id` (Int, Autoincrement)
- **Key Fields:** `facultyId` (Int, FK → `faculty.id`), `examId` (Int, FK → `exams.id`), `room` (String), `role` (`DutyRole`), `status` (`DutyStatus`, default `CONFIRMED`)
- **Indexes:** `@@index([facultyId])`, `@@index([examId])`

### 7. `DutySwapRequest` (mapped to `duty_swap_requests`)
- **Purpose:** Formal duty exchange agreement between two faculty members.
- **Primary Key:** `id` (Int, Autoincrement)
- **Key Fields:** `requesterDutyId` (Int, FK → `duties.id`), `targetDutyId` (Int, FK → `duties.id`), `requestedByFacultyId` (Int, FK → `faculty.id`), `status` (`DutySwapStatus`, default `PENDING`), `createdAt`, `updatedAt`
- **Indexes:** `@@index([status])`, `@@index([requesterDutyId])`, `@@index([targetDutyId])`, `@@index([requestedByFacultyId])`

### 8. `Bundle` (mapped to `bundles`)
- **Purpose:** Physical examination question paper / answer booklet parcel manifest.
- **Primary Key:** `id` (Int, Autoincrement)
- **Key Fields:** `bundleId` (String, Unique, mapped to `bundle_id`), `examId` (Int, FK → `exams.id`), `room` (String), `createdAt`
- **Indexes:** `@@index([examId])`, `@@index([room])`

### 9. `BundleScanLog` (mapped to `bundle_scan_logs`)
- **Purpose:** Audit record of bundle QR scan at point of entry.
- **Primary Key:** `id` (Int, Autoincrement)
- **Key Fields:** `bundleRecordId` (Int, FK → `bundles.id`), `facultyId` (Int, FK → `faculty.id`), `dutyId` (Int, FK → `duties.id`), `scannedAt` (DateTime, default `now()`)
- **Indexes:** `@@index([bundleRecordId])`, `@@index([facultyId])`, `@@index([dutyId])`, `@@index([scannedAt])`

### 10. `Attendance` (mapped to `attendance_marks`)
- **Purpose:** Record of verified student presence.
- **Primary Key:** `id` (Int, Autoincrement)
- **Key Fields:** `facultyId` (Int, FK → `faculty.id`), `dutyId` (Int, FK → `duties.id`), `studentIdentifier` (String, student URN or roll number), `createdAt`
- **Indexes:** `@@index([facultyId])`, `@@index([dutyId])`

### 11. `SupplyRequest` (mapped to `supply_requests`)
- **Purpose:** Realtime invigilator stationery/sheet replenishment request.
- **Primary Key:** `id` (Int, Autoincrement)
- **Key Fields:** `facultyId` (Int, FK → `faculty.id`), `dutyId` (Int, FK → `duties.id`), `item` (String), `quantity` (Int), `note` (String?, optional), `createdAt`
- **Indexes:** `@@index([facultyId])`, `@@index([dutyId])`

### 12. `WashroomLog` (mapped to `washroom_logs`)
- **Purpose:** Tracks bathroom break durations during examination sessions.
- **Primary Key:** `id` (Int, Autoincrement)
- **Key Fields:** `facultyId` (Int, FK → `faculty.id`), `dutyId` (Int, FK → `duties.id`), `studentId` (String), `startTime` (DateTime, default `now()`), `endTime` (DateTime?, nullable), `status` (`WashroomStatus`, default `ACTIVE`)
- **Indexes:** `@@index([facultyId])`, `@@index([dutyId])`, `@@index([endTime])`, `@@index([status])`

### 13. `SOSRequest` (mapped to `sos_requests`)
- **Purpose:** Emergency assistance distress calls from exam halls.
- **Primary Key:** `id` (Int, Autoincrement)
- **Key Fields:** `facultyId` (Int, FK → `faculty.id`), `message` (String), `status` (`SOSStatus`, default `PENDING`), `createdAt`
- **Indexes:** `@@index([facultyId])`, `@@index([status])`, `@@index([createdAt])`

### 14. `PostExamReport` (mapped to `post_exam_reports`)
- **Purpose:** Final invigilator reconciliation statement submitted at exam conclusion.
- **Primary Key:** `id` (Int, Autoincrement)
- **Key Fields:** `facultyId` (Int, FK → `faculty.id`), `dutyId` (Int, FK → `duties.id`), `totalStudentsPresent` (Int), `totalAnswerSheetsCollected` (Int), `noIncidents` (Boolean), `incidentDetails` (String?, optional), `remarks` (String?, optional), `declarationAccepted` (Boolean), `createdAt`
- **Indexes:** `@@index([facultyId])`, `@@index([dutyId])`, `@@index([createdAt])`

### 15. `ActivityLog` (mapped to `activity_logs`)
- **Purpose:** Hall-level audit log of invigilator operational events.
- **Primary Key:** `id` (Int, Autoincrement)
- **Key Fields:** `facultyId` (Int, FK → `faculty.id`), `dutyId` (Int, FK → `duties.id`), `type` (`ActivityType`), `message` (String), `createdAt`
- **Indexes:** `@@index([facultyId])`, `@@index([dutyId])`, `@@index([createdAt])`
