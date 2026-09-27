-- CreateEnum
CREATE TYPE "Role" AS ENUM ('STUDENT', 'FACULTY', 'ADMIN');

-- CreateEnum
CREATE TYPE "DutyRole" AS ENUM ('INVIGILATOR', 'LEAD');

-- CreateEnum
CREATE TYPE "DutyStatus" AS ENUM ('CONFIRMED', 'PENDING_SWAP');

-- CreateEnum
CREATE TYPE "SwapStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "WashroomStatus" AS ENUM ('ACTIVE', 'RETURNED', 'VIOLATION');

-- CreateEnum
CREATE TYPE "SOSStatus" AS ENUM ('PENDING', 'ACKNOWLEDGED', 'RESOLVED');

-- CreateEnum
CREATE TYPE "ActivityType" AS ENUM ('BUNDLE_SCANNED', 'ATTENDANCE_MARKED', 'SUPPLIES_REQUESTED', 'WASHROOM_STARTED', 'WASHROOM_ENDED', 'SOS_REQUESTED', 'REPORT_SUBMITTED');

-- CreateTable
CREATE TABLE "users" (
    "id" SERIAL NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "role" "Role" NOT NULL DEFAULT 'STUDENT',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "students" (
    "id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "roll_number" TEXT NOT NULL,
    "department" TEXT NOT NULL,
    "semester" INTEGER NOT NULL,

    CONSTRAINT "students_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "faculty" (
    "id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "department" TEXT NOT NULL,
    "designation" TEXT NOT NULL,

    CONSTRAINT "faculty_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "exams" (
    "id" SERIAL NOT NULL,
    "subject" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "time" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "exams_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "seating_allocations" (
    "id" SERIAL NOT NULL,
    "student_id" INTEGER NOT NULL,
    "exam_id" INTEGER NOT NULL,
    "room" TEXT NOT NULL,
    "seat_number" TEXT NOT NULL,

    CONSTRAINT "seating_allocations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "duties" (
    "id" SERIAL NOT NULL,
    "faculty_id" INTEGER NOT NULL,
    "exam_id" INTEGER NOT NULL,
    "room" TEXT NOT NULL,
    "role" "DutyRole" NOT NULL DEFAULT 'INVIGILATOR',
    "status" "DutyStatus" NOT NULL DEFAULT 'CONFIRMED',

    CONSTRAINT "duties_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "duty_swap_requests" (
    "id" SERIAL NOT NULL,
    "requester_duty_id" INTEGER NOT NULL,
    "target_duty_id" INTEGER NOT NULL,
    "requested_by_faculty_id" INTEGER NOT NULL,
    "status" "SwapStatus" NOT NULL DEFAULT 'PENDING',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "duty_swap_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bundles" (
    "id" SERIAL NOT NULL,
    "bundle_id" TEXT NOT NULL,
    "exam_id" INTEGER NOT NULL,
    "room" TEXT NOT NULL,

    CONSTRAINT "bundles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bundle_scan_logs" (
    "id" SERIAL NOT NULL,
    "bundle_record_id" INTEGER NOT NULL,
    "faculty_id" INTEGER NOT NULL,
    "duty_id" INTEGER NOT NULL,
    "scanned_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bundle_scan_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "attendance_marks" (
    "id" SERIAL NOT NULL,
    "faculty_id" INTEGER NOT NULL,
    "duty_id" INTEGER NOT NULL,
    "student_identifier" TEXT NOT NULL,
    "marked_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "attendance_marks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "supply_requests" (
    "id" SERIAL NOT NULL,
    "faculty_id" INTEGER NOT NULL,
    "duty_id" INTEGER NOT NULL,
    "item" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL,
    "note" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "supply_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "washroom_logs" (
    "id" SERIAL NOT NULL,
    "faculty_id" INTEGER NOT NULL,
    "duty_id" INTEGER NOT NULL,
    "student_id" TEXT NOT NULL,
    "start_time" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "end_time" TIMESTAMP(3),
    "status" "WashroomStatus" NOT NULL DEFAULT 'ACTIVE',

    CONSTRAINT "washroom_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sos_requests" (
    "id" SERIAL NOT NULL,
    "faculty_id" INTEGER NOT NULL,
    "message" TEXT NOT NULL,
    "status" "SOSStatus" NOT NULL DEFAULT 'PENDING',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sos_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "post_exam_reports" (
    "id" SERIAL NOT NULL,
    "faculty_id" INTEGER NOT NULL,
    "duty_id" INTEGER NOT NULL,
    "total_students_present" INTEGER NOT NULL,
    "total_answer_sheets_collected" INTEGER NOT NULL,
    "no_incidents" BOOLEAN NOT NULL,
    "incident_details" TEXT,
    "remarks" TEXT,
    "declaration_accepted" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "post_exam_reports_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "activity_logs" (
    "id" SERIAL NOT NULL,
    "faculty_id" INTEGER NOT NULL,
    "duty_id" INTEGER NOT NULL,
    "type" "ActivityType" NOT NULL,
    "message" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "activity_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "students_user_id_key" ON "students"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "students_roll_number_key" ON "students"("roll_number");

-- CreateIndex
CREATE UNIQUE INDEX "faculty_user_id_key" ON "faculty"("user_id");

-- CreateIndex
CREATE INDEX "seating_allocations_exam_id_idx" ON "seating_allocations"("exam_id");

-- CreateIndex
CREATE INDEX "duties_faculty_id_idx" ON "duties"("faculty_id");

-- CreateIndex
CREATE INDEX "duties_exam_id_idx" ON "duties"("exam_id");

-- CreateIndex
CREATE INDEX "duty_swap_requests_status_idx" ON "duty_swap_requests"("status");

-- CreateIndex
CREATE INDEX "duty_swap_requests_requester_duty_id_idx" ON "duty_swap_requests"("requester_duty_id");

-- CreateIndex
CREATE INDEX "duty_swap_requests_target_duty_id_idx" ON "duty_swap_requests"("target_duty_id");

-- CreateIndex
CREATE INDEX "duty_swap_requests_requested_by_faculty_id_idx" ON "duty_swap_requests"("requested_by_faculty_id");

-- CreateIndex
CREATE UNIQUE INDEX "bundles_bundle_id_key" ON "bundles"("bundle_id");

-- CreateIndex
CREATE INDEX "bundles_exam_id_idx" ON "bundles"("exam_id");

-- CreateIndex
CREATE INDEX "bundles_room_idx" ON "bundles"("room");

-- CreateIndex
CREATE INDEX "bundle_scan_logs_bundle_record_id_idx" ON "bundle_scan_logs"("bundle_record_id");

-- CreateIndex
CREATE INDEX "bundle_scan_logs_faculty_id_idx" ON "bundle_scan_logs"("faculty_id");

-- CreateIndex
CREATE INDEX "bundle_scan_logs_duty_id_idx" ON "bundle_scan_logs"("duty_id");

-- CreateIndex
CREATE INDEX "bundle_scan_logs_scanned_at_idx" ON "bundle_scan_logs"("scanned_at");

-- CreateIndex
CREATE INDEX "attendance_marks_faculty_id_idx" ON "attendance_marks"("faculty_id");

-- CreateIndex
CREATE INDEX "attendance_marks_duty_id_idx" ON "attendance_marks"("duty_id");

-- CreateIndex
CREATE INDEX "supply_requests_faculty_id_idx" ON "supply_requests"("faculty_id");

-- CreateIndex
CREATE INDEX "supply_requests_duty_id_idx" ON "supply_requests"("duty_id");

-- CreateIndex
CREATE INDEX "washroom_logs_faculty_id_idx" ON "washroom_logs"("faculty_id");

-- CreateIndex
CREATE INDEX "washroom_logs_duty_id_idx" ON "washroom_logs"("duty_id");

-- CreateIndex
CREATE INDEX "washroom_logs_end_time_idx" ON "washroom_logs"("end_time");

-- CreateIndex
CREATE INDEX "washroom_logs_status_idx" ON "washroom_logs"("status");

-- CreateIndex
CREATE INDEX "sos_requests_faculty_id_idx" ON "sos_requests"("faculty_id");

-- CreateIndex
CREATE INDEX "sos_requests_status_idx" ON "sos_requests"("status");

-- CreateIndex
CREATE INDEX "sos_requests_created_at_idx" ON "sos_requests"("created_at");

-- CreateIndex
CREATE INDEX "post_exam_reports_faculty_id_idx" ON "post_exam_reports"("faculty_id");

-- CreateIndex
CREATE INDEX "post_exam_reports_duty_id_idx" ON "post_exam_reports"("duty_id");

-- CreateIndex
CREATE INDEX "post_exam_reports_created_at_idx" ON "post_exam_reports"("created_at");

-- CreateIndex
CREATE INDEX "activity_logs_faculty_id_idx" ON "activity_logs"("faculty_id");

-- CreateIndex
CREATE INDEX "activity_logs_duty_id_idx" ON "activity_logs"("duty_id");

-- CreateIndex
CREATE INDEX "activity_logs_created_at_idx" ON "activity_logs"("created_at");

-- AddForeignKey
ALTER TABLE "students" ADD CONSTRAINT "students_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "faculty" ADD CONSTRAINT "faculty_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "seating_allocations" ADD CONSTRAINT "seating_allocations_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "seating_allocations" ADD CONSTRAINT "seating_allocations_exam_id_fkey" FOREIGN KEY ("exam_id") REFERENCES "exams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "duties" ADD CONSTRAINT "duties_faculty_id_fkey" FOREIGN KEY ("faculty_id") REFERENCES "faculty"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "duties" ADD CONSTRAINT "duties_exam_id_fkey" FOREIGN KEY ("exam_id") REFERENCES "exams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "duty_swap_requests" ADD CONSTRAINT "duty_swap_requests_requester_duty_id_fkey" FOREIGN KEY ("requester_duty_id") REFERENCES "duties"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "duty_swap_requests" ADD CONSTRAINT "duty_swap_requests_target_duty_id_fkey" FOREIGN KEY ("target_duty_id") REFERENCES "duties"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "duty_swap_requests" ADD CONSTRAINT "duty_swap_requests_requested_by_faculty_id_fkey" FOREIGN KEY ("requested_by_faculty_id") REFERENCES "faculty"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bundles" ADD CONSTRAINT "bundles_exam_id_fkey" FOREIGN KEY ("exam_id") REFERENCES "exams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bundle_scan_logs" ADD CONSTRAINT "bundle_scan_logs_bundle_record_id_fkey" FOREIGN KEY ("bundle_record_id") REFERENCES "bundles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bundle_scan_logs" ADD CONSTRAINT "bundle_scan_logs_faculty_id_fkey" FOREIGN KEY ("faculty_id") REFERENCES "faculty"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bundle_scan_logs" ADD CONSTRAINT "bundle_scan_logs_duty_id_fkey" FOREIGN KEY ("duty_id") REFERENCES "duties"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_marks" ADD CONSTRAINT "attendance_marks_faculty_id_fkey" FOREIGN KEY ("faculty_id") REFERENCES "faculty"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_marks" ADD CONSTRAINT "attendance_marks_duty_id_fkey" FOREIGN KEY ("duty_id") REFERENCES "duties"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "supply_requests" ADD CONSTRAINT "supply_requests_faculty_id_fkey" FOREIGN KEY ("faculty_id") REFERENCES "faculty"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "supply_requests" ADD CONSTRAINT "supply_requests_duty_id_fkey" FOREIGN KEY ("duty_id") REFERENCES "duties"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "washroom_logs" ADD CONSTRAINT "washroom_logs_faculty_id_fkey" FOREIGN KEY ("faculty_id") REFERENCES "faculty"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "washroom_logs" ADD CONSTRAINT "washroom_logs_duty_id_fkey" FOREIGN KEY ("duty_id") REFERENCES "duties"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sos_requests" ADD CONSTRAINT "sos_requests_faculty_id_fkey" FOREIGN KEY ("faculty_id") REFERENCES "faculty"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_exam_reports" ADD CONSTRAINT "post_exam_reports_faculty_id_fkey" FOREIGN KEY ("faculty_id") REFERENCES "faculty"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_exam_reports" ADD CONSTRAINT "post_exam_reports_duty_id_fkey" FOREIGN KEY ("duty_id") REFERENCES "duties"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity_logs" ADD CONSTRAINT "activity_logs_faculty_id_fkey" FOREIGN KEY ("faculty_id") REFERENCES "faculty"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity_logs" ADD CONSTRAINT "activity_logs_duty_id_fkey" FOREIGN KEY ("duty_id") REFERENCES "duties"("id") ON DELETE CASCADE ON UPDATE CASCADE;
