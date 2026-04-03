-- Script Thêm Dữ Liệu Mẫu (Seed Data) cho Ứng Dụng Đặt Vé Nhóm 7

-- 1. Thông Tin Tài Khoản
INSERT INTO [ThongTinTaiKhoan] (maTaiKhoan, hoTen, ngaySinh, gioiTinh, sdt, email, matKhau) VALUES
('TK001', N'Nguyễn Văn A', '1995-05-12', 1, '0901234567', 'nguyenvana@gmail.com', '123456'),
('TK002', N'Trần Thị B', '1998-11-23', 0, '0912345678', 'tranthib@gmail.com', '123456');

-- 2. Thể Loại
INSERT INTO [TheLoai] (maTheLoai, tenTheLoai, moTa) VALUES
('TL01', N'Hành Động', N'Phim có nhiều cảnh đánh nhau, rượt đuổi.'),
('TL02', N'Tình Cảm', N'Phim lãng mạn, gia đình.'),
('TL03', N'Khoa Học Viễn Tưởng', N'Phim lấy bối cảnh tương lai, vũ trụ.');

-- 3. Hashtag
INSERT INTO [Hashtag] (maHashtag, tenHashTag) VALUES
('HT01', N'#BomTan'),
('HT02', N'#PhimVietNam'),
('HT03', N'#HanhDong');

-- 4. Đạo Diễn & Diễn Viên
INSERT INTO [DaoDien] (maDaoDien, tenDaoDien, quocTich) VALUES
('DD01', N'Denis Villeneuve', N'Canada'),
('DD02', N'Trấn Thành', N'Việt Nam');

INSERT INTO [DienVien] (maDienVien, tenDienVien, quocTich) VALUES
('DV01', N'Timothée Chalamet', N'Mỹ'),
('DV02', N'Phương Anh Đào', N'Việt Nam');

-- 5. Phim
INSERT INTO [Phim] (maPhim, tenPhim, ngayRaMat, moTa, thoiLuong, gioiHanTuoi, poster_url, trailer_url, trangThai, duocTaoBoi) VALUES
('P001', N'DUNE: HÀNH TINH CÁT 2', '2024-03-01', N'Phần 2 của siêu phẩm Dune.', 166, 16, 'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2TGbiROox.jpg', 'https://youtube.com', 'showing', 'Admin'),
('P002', N'MAI', '2024-02-10', N'Cú sốc phòng vé phim Việt Tết 2024.', 131, 18, 'https://upload.wikimedia.org/wikipedia/vi/a/a8/Mai_2024_poster.jpg', 'https://youtube.com', 'showing', 'Admin'),
('P003', N'KUNG FU PANDA 4', '2024-03-08', N'Gấu trúc Po trở lại.', 94, 0, 'https://image.tmdb.org/t/p/w500/kDp1vUBnMpe8ak4rjgl3cLELqjU.jpg', 'https://youtube.com', 'coming_soon', 'Admin');

-- 6. Liên kết Phim với Thể Loại, Đạo Diễn, Diễn Viên, Hashtag
INSERT INTO [Phim_TheLoai] (maPhim, maTheLoai) VALUES ('P001', 'TL01'), ('P001', 'TL03'), ('P002', 'TL02');
INSERT INTO [Phim_DaoDien] (maPhim, maDaoDien) VALUES ('P001', 'DD01'), ('P002', 'DD02');
INSERT INTO [Phim_DienVien] (maPhim, maDienVien) VALUES ('P001', 'DV01'), ('P002', 'DV02');
INSERT INTO [Phim_HashTag] (maPhim, maHashtag) VALUES ('P001', 'HT01'), ('P002', 'HT02');

-- 7. Rạp Phim, Phòng Rạp, Ghế, Nhân Viên
INSERT INTO [RapPhim] (maRapPhim, tenRapPhim, diaChi) VALUES
('R001', N'Nhóm 7 Cinema Sư Vạn Hạnh', N'Tầng 5, Vạn Hạnh Mall, Q10, TP.HCM');

INSERT INTO [PhongRapPhim] (maPhong, tenPhong, soLuongGhe, maRapPhim) VALUES
('PR01', N'Phòng IMAX', 64, 'R001');

INSERT INTO [NhanVien] (maNhanVien, hoTen, ngaySinh, sdt, email, matKhau, vaiTro) VALUES
('NV01', N'Quản Lý Rạp', '1990-01-01', '0922222222', 'ql@nhom7.com', '123456', N'Quản Lý');
INSERT INTO [RapPhim_NhanVien] (ID_NhanVien, maRapPhim) VALUES (1, 'R001');

-- (Vì ghế có quá nhiều nên ta chỉ nhập mẫu vài ghế đầu)
INSERT INTO [GheNgoi] (maGhe, maHangGhe, soGhe, loaiGhe, heSoGiaGhe, maPhong) VALUES
('G001', 'A', 1, 'normal', 1.0, 'PR01'),
('G002', 'A', 2, 'normal', 1.0, 'PR01'),
('G003', 'F', 1, 'vip', 1.5, 'PR01'),
('G004', 'K', 1, 'couple', 2.0, 'PR01');

-- 8. Lịch Chiếu
INSERT INTO [LichChieu] (maLichChieu, ngayChieu, gioChieu, gioKetThuc, giaVe, maPhim, maPhong) VALUES
('LC001', '2024-04-10', '2024-04-10 18:00:00', '2024-04-10 20:46:00', 100000, 'P001', 'PR01'),
('LC002', '2024-04-10', '2024-04-10 21:00:00', '2024-04-10 23:11:00', 90000, 'P002', 'PR01');

SELECT N'Đã hoàn thành Insert dữ liệu mẫu' AS [Status];
