# EXAMS — DATABASE MIGRATION STRATEGY
**Subsystem:** Database Management & Schema Governance  
**Status:** Established Phase 1 Baseline  
**Prisma ORM Version:** `v6.5.0` (Standardized)  
**Database Target:** PostgreSQL 17  

---

## 1. Background & Historic Deficiencies

During prototype and early alpha development, schema iterations were managed using:
```bash
npm run setup # executed prisma generate && prisma db push
```
`prisma db push` synchronizes schema definitions directly with the target database without maintaining a versioned migration trail or audit log.
While suitable for prototyping, this approach introduces severe production risks:
- Inability to perform reproducible deployments across staging and production.
- High risk of accidental table drops or column data loss during schema drift resolution.
- Running `prisma migrate dev` against an existing database without a baseline triggers Prisma's interactive warning:
  > *"We need to reset the PostgreSQL database. All data will be lost. Do you want to continue? [y/N]"*

---

## 2. Phase 1 Safe Migration Baselining

Per Phase 1 strict non-destructive constraints, no tables were dropped, no truncate commands were executed, and `prisma migrate reset` was strictly prohibited.

The migration baseline was established using Prisma's non-destructive schema diff mechanism:
```bash
npx prisma migrate diff --from-empty --to-schema-datamodel prisma/schema.prisma --script
```
This generated the authoritative baseline migration:
- **Location:** `backend/prisma/migrations/0_init/migration.sql`
- **Contents:**
  - 7 Enums (`Role`, `DutyRole`, `DutyStatus`, `SwapStatus`, `WashroomStatus`, `SOSStatus`, `ActivityType`)
  - 15 Tables (`users`, `students`, `faculty`, `exams`, `seating_allocations`, `duties`, `duty_swap_requests`, `bundles`, `bundle_scan_logs`, `attendance_marks`, `supply_requests`, `washroom_logs`, `sos_requests`, `post_exam_reports`, `activity_logs`)
  - 29 Foreign Key constraints and indices.

---

## 3. Deployment & Execution Procedure for Existing vs. New Databases

### Scenario A: Deploying on an Existing Database (With Existing Data)
To prevent Prisma from attempting to recreate already-existing tables or prompting for a reset, the baseline migration must be marked as applied:
```bash
npx prisma migrate resolve --applied 0_init
```
This inserts a record for `0_init` into the `_prisma_migrations` table without executing the SQL statements against PostgreSQL. All data remains 100% intact.

### Scenario B: Provisioning a Clean / New Development Database
When initializing a brand new PostgreSQL container or CI/CD test database:
```bash
npx prisma migrate deploy
npm run prisma:seed
```
This executes `0_init/migration.sql` sequentially and seeds initial development fixtures.

### Scenario C: Future Schema Changes (Phase 2+)
Any future changes to `backend/prisma/schema.prisma` must be versioned:
1. Update `schema.prisma`.
2. Generate a named migration:
   ```bash
   npx prisma migrate dev --name <descriptive_name>
   ```
3. Never use `prisma db push` in production branches.

---

## 4. Invariant Rules for Database Operations

1. **NO DESTRUCTIVE RESET:** Never run `prisma migrate reset` or `prisma db push --force-reset` on shared or production instances.
2. **SEED SAFETY:** `backend/prisma/seed.js` includes table cleanup statements (`deleteMany`). In production environments, seed scripts must only be run on initial provisioning or with guarded environment checks (`NODE_ENV === 'development'`).
3. **VERSION LOCK:** Prisma CLI and `@prisma/client` are locked to `^6.5.0` in both `backend/package.json` and the workspace root `package.json`.
