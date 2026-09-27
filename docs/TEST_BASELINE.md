# EXAMS — TEST BASELINE REPORT

## 1. Backend Test Suite

### Execution Summary
- **Test Runner:** Jest (v29.7.0) via `npm test` (`jest --runInBand`)
- **Execution Result:** **ALL 14 TESTS PASSED**
- **Test Suites:** 5 passed, 5 total
- **Execution Time:** ~1.31 s

### Suite Breakdown
1. `backend/tests/authController.test.js`:
   - `creates a linked faculty profile when registering a faculty user` (PASS)
   - *Coverage Gap:* `login` function is not tested; password hashing failure paths and invalid email paths are not covered.
2. `backend/tests/authMiddleware.test.js`:
   - `blocks access when the authenticated user does not have the required role` (PASS)
   - *Coverage Gap:* Token expiration, invalid token signature, and missing Authorization header are not covered in unit test.
3. `backend/tests/adminController.test.js`:
   - `approves a pending swap and returns the updated status` (PASS)
   - *Coverage Gap:* `getDashboard` and `resolveSOS` have zero unit test coverage.
4. `backend/tests/facultyController.test.js`:
   - `returns only the authenticated faculty duties` (PASS)
   - `filters swap options to exclude current duty and current faculty` (PASS)
   - `creates a pending swap request and updates duties` (PASS)
   - `rejects swap requests when duties are not confirmed` (PASS)
5. `backend/tests/dashboardController.test.js`:
   - Bundle scan validation and success (PASS)
   - Attendance marking (PASS)
   - Supplies request (PASS)
   - Washroom timer start and end (PASS)
   - SOS request creation and count verification (PASS)
   - Post-exam report validation and creation (PASS)
   - Activity feed retrieval (PASS)

### Critical Backend Testing Issues
1. **No Student Controller Tests:** `studentController.js` has zero tests (`getAssignedExams` and `getStudentSeating` are untested).
2. **No Integration / Supertest Tests:** All tests are unit tests using mocked Prisma objects (`findUnique`, `$transaction`). HTTP request pipeline, middleware chaining, and PostgreSQL constraints are not verified in integration suites.
3. **Socket.IO Unit Test Noise:** Because Socket.IO is not mocked or abstracted inside `dashboardController.js` and `facultyController.js`, unit tests print `console.error("Socket emit failed: Socket.io not initialized!")` repeatedly during execution.

---

## 2. Frontend Test Suite (Flutter)

### Execution Summary
- **Test Runner:** Flutter Test Framework via `dart-mcp-server` `run_tests`
- **Total Tests Executed:** 15
- **Passing Tests:** 7
- **Failing Tests:** 8
- **Status:** **BROKEN (8 FAILING TESTS)**

### Failure Analysis
1. `faculty_dashboard_screen_test.dart: shows a green snackbar after a successful bundle scan`
   - *Error:* `There are multiple heroes that share the same tag within a subtree: <default FloatingActionButton tag>` and `StateError: Bad state: No element`.
   - *Cause:* Duplicate default FloatingActionButton Hero tag in modal / sheet hierarchy, causing Flutter framework assertion error.
2. `faculty_dashboard_screen_test.dart: shows a red snackbar when bundle scan fails`
   - *Error:* Hero tag collision and finder evaluation failure.
3. `faculty_dashboard_screen_test.dart: renders live washroom cards with student ID and status`
   - *Error:* `Found 0 widgets with text "Student ID: STU-42"`.
   - *Cause:* UI label formatting changed in `faculty_dashboard_screen.dart`.
4. `faculty_dashboard_screen_test.dart: shows SOS actions with pending count`
   - *Error:* `Found 0 widgets with text "2 Pending"`.
   - *Cause:* Badge text or layout changed.
5. `faculty_dashboard_screen_test.dart: shows post-exam report action on the dashboard`
   - *Error:* `Found 0 widgets with text "Post-Exam Report"`.
   - *Cause:* Post-exam report button is wrapped in a conditional check (`count.label == 'Exam Completed'`), which is false during initial test pump.
6. `faculty_duties_screen_test.dart: renders faculty duty cards and status badges`
   - *Error:* `Found 0 widgets with text "Physics"`.
   - *Cause:* Card layout was modified or subject text was formatted differently.
7. `post_exam_report_screen_test.dart: requires declaration before report submission`
   - *Error:* `Found 0 widgets with text "Submit & Generate Report"`.
   - *Cause:* Submit button label in `post_exam_report_screen.dart` is "Submit" or differs from test expectation.
8. `post_exam_report_screen_test.dart: renders structured report layout`
   - *Error:* `Found 0 widgets with text "Irregularities & Incidents"`.
   - *Cause:* Section header label in screen differs from test finder string.

### Missing Critical Coverage (Flutter)
- Zero tests for `student_schedule_screen.dart` (which contains hardcoded mock data).
- Zero tests for `student_profile_screen.dart`.
- Zero tests for `admin_dashboard_screen.dart` (Socket.IO client, SOS resolve, Swap approve).
- Zero tests for `faculty_swaps_screen.dart`, `faculty_colleagues_screen.dart`, `faculty_settings_screen.dart`.
