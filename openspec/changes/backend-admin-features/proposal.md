## Why

The backend administration features need to be updated to support edge cases in daily theater operations and improve data extraction. Specifically, it needs to handle broken seats, pending payments, automate showtime calculations to prevent human errors, and provide statistical reports in Excel format for better flexibility compared to PDF.

## What Changes

- Modify database constraints to allow `hỏng` as a seat type and `pending` as a payment status.
- Update `showtimeAdminController.js` to automatically calculate `gioKetThuc` based on movie duration instead of taking it from user input.
- Replace `PUT /rooms/:id/seats` with `PUT /seats/:id/status` (or similar) to allow admins to mark seats as broken without recreating the whole room map.
- Remove outdated customer update endpoint and improve `getBookings` to return full booking details.
- Add an API for admins to change payment status `PUT /api/admin/payments/:id/status`.
- Replace PDF generation (`pdfkit`) with Excel generation (`exceljs`) in `statsController.js` for monthly reports.
- Add a new daily revenue statistics API `GET /api/admin/stats/daily-revenue`.

## Capabilities

### New Capabilities
- `admin-operations`: Core operations for admins including changing seat statuses to broken, manually updating payment statuses, and automating showtime end time calculation.
- `admin-reporting`: Generating administrative reports in Excel format and calculating daily and monthly revenues.

### Modified Capabilities
- N/A (No existing specs).

## Impact

- `backend/controllers/admin/` (showtimeAdminController.js, roomAdminController.js, customerAdminController.js, statsController.js)
- `backend/routes/adminRoutes.js`
- Database schema (`ghengoi`, `thongtinthanhtoan` constraints)
- Dependencies: Removing `pdfkit`, adding `exceljs`
