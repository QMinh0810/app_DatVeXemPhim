## Context

The backend currently lacks some edge-case management capabilities for administrators, such as marking seats as broken, changing payment states to pending, and extracting reports in Excel format. It also relies on manual input for showtime end times, which can lead to inconsistencies. We are adding these administrative features directly to the Node.js/Express backend and modifying the PostgreSQL database constraints.

## Goals / Non-Goals

**Goals:**
- Provide APIs for admins to manage individual seat statuses and payment statuses.
- Automate showtime end-time calculation to reduce manual entry errors.
- Export monthly statistical reports as Excel `.xlsx` files.
- Track daily revenue.

**Non-Goals:**
- Frontend flutter updates (handled separately or not part of this backend task).
- Full database migration tool implementation (we will use direct SQL `ALTER TABLE`).

## Decisions

- **Direct SQL execution for Constraints:** We will manually run `ALTER TABLE` to update `ghengoi_loaighe_check` and `thongtinthanhtoan_trangthai_check` to add the new states.
- **Library Replacement:** Replace `pdfkit` with `exceljs` in `statsController.js` to build the new XLSX report format.
- **Removal of Room Regeneration Endpoint:** We are dropping the `regenerateSeats` API in favor of updating specific seats. This prevents accidental deletion of existing booked seats.

## Risks / Trade-offs

- **Risk**: Altering DB constraints directly might lock tables temporarily in production.
  **Mitigation**: Perform the ALTER during off-peak hours or ensure constraints are updated safely.
- **Risk**: Modifying `getBookings` might impact existing admin UI if fields are unexpectedly removed.
  **Mitigation**: We will ensure the new query returns all necessary data points including `Mã Vé, tên khách hàng, Phim, Ghế, ngày chiếu, tổng tiền, trạng thái`.
