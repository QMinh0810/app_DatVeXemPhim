## 1. Database Schema Modifications

- [x] 1.1 Run SQL command to update `ghengoi_loaighe_check` constraint to include `hỏng`
- [x] 1.2 Run SQL command to update `thongtinthanhtoan_trangthai_check` constraint to include `pending`

## 2. Showtime Auto Calculation

- [x] 2.1 Update `createShowtime` in `backend/controllers/admin/showtimeAdminController.js` to query movie `thoiLuong`
- [x] 2.2 Implement auto-calculation of `gioKetThuc` (`gioChieu` + `thoiLuong` + 15 mins)

## 3. Seat Management Enhancements

- [x] 3.1 Remove `regenerateSeats` from `backend/controllers/admin/roomAdminController.js` and delete `PUT /rooms/:id/seats` route
- [x] 3.2 Add `updateSeatType` in `roomAdminController.js`
- [x] 3.3 Add new route `PUT /seats/:id/status` in `backend/routes/adminRoutes.js` for updating seat statuses

## 4. Customer and Payment Management

- [x] 4.1 Remove `updateCustomer` from `backend/controllers/admin/customerAdminController.js` and its route
- [x] 4.2 Update `getBookings` query to return full details (`Mã Vé`, `Tên khách hàng`, `Phim`, `Ghế`, `Ngày chiếu`, `Tổng tiền`, `Trạng thái`)
- [x] 4.3 Add implementation for updating payment status in `customerAdminController.js`
- [x] 4.4 Add new route `PUT /payments/:id/status` in `backend/routes/adminRoutes.js`

## 5. Reporting and Statistics

- [x] 5.1 Run `npm install exceljs` and uninstall `pdfkit` in `backend/`
- [x] 5.2 Modify `revenueByMovie` in `backend/controllers/admin/statsController.js` to return ticket count (`COUNT(v.mavexemphim)`) instead of order count
- [x] 5.3 Rewrite `monthlyReport` in `statsController.js` to build and export `.xlsx` files using `exceljs`
- [x] 5.4 Implement `dailyRevenueStats` in `statsController.js` to aggregate ticket and F&B revenue grouped by date
- [x] 5.5 Add route `GET /stats/daily-revenue` in `backend/routes/adminRoutes.js`
