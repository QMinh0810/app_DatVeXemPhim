Create table [ThongTinTaiKhoan] (
	[ID_Khach] Integer IDENTITY(1,1) NOT NULL,
	[maTaiKhoan] Varchar(10) NOT NULL UNIQUE,
	[hoTen] Nvarchar(100) NOT NULL,
	[ngaySinh] Datetime NOT NULL,
	[gioiTinh] Bit NULL Check (gioiTinh in (1, 0) ),
	[sdt] Char(11) NOT NULL UNIQUE,
	[email] Varchar(100) NOT NULL UNIQUE,
	[matKhau] Varchar(100) NOT NULL,
	[anhDaiDien] Varchar(500) NULL,
	[ngayTao] Datetime Default GETDATE() NOT NULL,
	[ngayCapNhat] Datetime Default GETDATE() NOT NULL,
Primary Key  ([ID_Khach])
) 
go

Create table [Phim] (
	[maPhim] Varchar(10) NOT NULL,
	[tenPhim] Nvarchar(100) NOT NULL,
	[ngayRaMat] Datetime NOT NULL,
	[moTa] Nvarchar(300) NOT NULL,
	[thoiLuong] Integer NOT NULL,
	[gioiHanTuoi] Integer NOT NULL,
	[poster_url] Varchar(500) NOT NULL,
	[trailer_url] Varchar(500) NOT NULL,
	[trangThai] Varchar(10) Default 'coming_soon' NOT NULL Check (trangThai IN (N'showing', N'coming_soon', N'hidden', N'banned') ),
	[duocTaoBoi] Nvarchar(100) NOT NULL,
	[duocTaoNgay] Datetime Default GETDATE() NOT NULL,
Primary Key  ([maPhim])
) 
go

Create table [TheLoai] (
	[maTheLoai] Varchar(10) NOT NULL,
	[tenTheLoai] Nvarchar(100) NOT NULL,
	[moTa] Nvarchar(500) NULL,
Primary Key  ([maTheLoai])
) 
go

Create table [Phim_TheLoai] (
	[maPhim] Varchar(10) NOT NULL,
	[maTheLoai] Varchar(10) NOT NULL,
Primary Key  ([maPhim],[maTheLoai])
) 
go

Create table [Hashtag] (
	[maHashtag] Varchar(10) NOT NULL,
	[tenHashTag] Nvarchar(100) NOT NULL,
Primary Key  ([maHashtag])
) 
go

Create table [Phim_HashTag] (
	[maPhim] Varchar(10) NOT NULL,
	[maHashtag] Varchar(10) NOT NULL,
Primary Key  ([maPhim],[maHashtag])
) 
go

Create table [RapPhim] (
	[maRapPhim] Varchar(10) NOT NULL,
	[tenRapPhim] Nvarchar(100) NOT NULL,
	[diaChi] Nvarchar(200) NOT NULL,
Primary Key  ([maRapPhim])
) 
go

Create table [PhongRapPhim] (
	[maPhong] Varchar(10) NOT NULL,
	[tenPhong] Nvarchar(50) NOT NULL,
	[soLuongGhe] Integer NULL,
	[maRapPhim] Varchar(10) NOT NULL,
Primary Key  ([maPhong])
) 
go

Create table [GheNgoi] (
	[maGhe] Varchar(10) NOT NULL,
	[maHangGhe] Varchar(5) NOT NULL,
	[soGhe] Integer NOT NULL,
	[loaiGhe] Nvarchar(100) NOT NULL Check (loaiGhe IN (N'normal', N'vip', N'couple') ),
	[heSoGiaGhe] Float Default 1 NOT NULL,
	[maPhong] Varchar(10) NOT NULL,
Primary Key  ([maGhe])
) 
go

Create table [LichChieu] (
	[maLichChieu] Varchar(10) NOT NULL,
	[ngayChieu] Datetime NOT NULL,
	[gioChieu] Datetime NOT NULL,
	[gioKetThuc] Datetime NOT NULL,
	[giaVe] Integer NOT NULL,
	[maPhim] Varchar(10) NOT NULL,
	[maPhong] Varchar(10) NOT NULL,
Primary Key  ([maLichChieu])
) 
go

Create table [DonDatVe] (
	[maDonDatVe] Varchar(10) NOT NULL,
	[ngayDatVe] Datetime Default GETDATE() NOT NULL,
	[tongTien] Integer Default 0 NOT NULL,
	[trangThai] Nvarchar(50) Default N'pending' NOT NULL Check (trangThai IN (N'pending', N'paid', N'cancelled') ),
	[ID_Khach] Integer NOT NULL,
Primary Key  ([maDonDatVe])
) 
go

Create table [VeXemPhim] (
	[maVeXemPhim] Varchar(10) NOT NULL,
	[qrCode] Varchar(200) NULL,
	[thoiGianPhatHanh] Datetime Default GETDATE() NOT NULL,
	[trangThai] Varchar(50) NOT NULL,
	[thoiGianHetHan] Datetime NOT NULL,
	[giaVe] Integer NOT NULL,
	[maGhe] Varchar(10) NOT NULL,
	[maLichChieu] Varchar(10) NOT NULL,
	[maDonDatVe] Varchar(10) NOT NULL,
Primary Key  ([maVeXemPhim])
) 
go

Create table [ThongTinThanhToan] (
	[maThanhToan] Varchar(10) NOT NULL,
	[phuongThucThanhToan] Varchar(10) NOT NULL Check (phuongThucThanhToan IN (N'momo', N'vnpay') ),
	[paymentGatewayTransactionId] Varchar(100) NOT NULL,
	[soTienThanhToan] Integer NOT NULL,
	[thoiDiemThanhToan] Datetime Default GETDATE() NOT NULL,
	[trangThai] Varchar(50) NOT NULL Check (trangThai IN (N'success', N'failed') ),
	[maDonDatVe] Varchar(10) NOT NULL,
Primary Key  ([maThanhToan])
) 
go

Create table [BinhLuan] (
	[maBinhLuan] Varchar(10) NOT NULL,
	[maPhim] Varchar(10) NOT NULL,
	[noiDung] Nvarchar(500) NULL,
	[danhGia] Integer NOT NULL Check (danhGia BETWEEN 1 AND 10 ),
	[thoiDiemDanhGia] Datetime Default GETDATE() NOT NULL,
	[ID_Khach] Integer NOT NULL,
	[ID_NhanVien] Integer NULL,
	[noiDungReply] Nvarchar(500) NULL,
Primary Key  ([maBinhLuan])
) 
go

Create table [ThongBao] (
	[maThongBao] Varchar(10) NOT NULL,
	[noiDung] Nvarchar(1000) NOT NULL,
	[thoiDiemTB] Datetime Default GETDATE() NOT NULL,
	[trangThai] Varchar(50) NULL,
	[tieuDe] Nvarchar(200) NOT NULL,
	[ngayTao] Datetime NOT NULL,
	[thoiDiemXem] Datetime NULL,
	[ID_Khach] Integer NOT NULL,
	[maDonDatVe] Varchar(10) NOT NULL,
	[maPhim] Varchar(10) NOT NULL,
Primary Key  ([maThongBao])
) 
go

Create table [NhanVien] (
	[ID_NhanVien] Integer IDENTITY(1,1) NOT NULL,
	[maNhanVien] Varchar(10) NOT NULL UNIQUE,
	[hoTen] Nvarchar(100) NOT NULL,
	[ngaySinh] Datetime NOT NULL,
	[gioiTinh] Bit NULL Check (gioiTinh in (1, 0) ),
	[sdt] Char(11) NOT NULL UNIQUE,
	[email] Varchar(100) NOT NULL UNIQUE,
	[matKhau] Varchar(100) NOT NULL,
	[anhDaiDien] Varchar(500) NULL,
	[vaiTro] Nvarchar(50) NOT NULL,
	[ngayTao] Datetime Default GETDATE() NOT NULL,
	[ngayCapNhat] Datetime Default GETDATE() NOT NULL,
Primary Key  ([ID_NhanVien])
) 
go

Create table [RapPhim_NhanVien] (
	[ID_NhanVien] Integer NOT NULL,
	[maRapPhim] Varchar(10) NOT NULL,
Primary Key  ([ID_NhanVien],[maRapPhim])
) 
go

Create table [DienVien] (
	[maDienVien] Varchar(10) NOT NULL,
	[tenDienVien] Nvarchar(100) NOT NULL,
	[ngaySinh] Datetime NULL,
	[quocTich] Nvarchar(100) NULL,
Primary Key  ([maDienVien])
) 
go

Create table [Phim_DienVien] (
	[maDienVien] Varchar(10) NOT NULL,
	[maPhim] Varchar(10) NOT NULL,
Primary Key  ([maDienVien],[maPhim])
) 
go

Create table [DaoDien] (
	[maDaoDien] Varchar(10) NOT NULL,
	[tenDaoDien] Nvarchar(100) NOT NULL,
	[ngaySinh] Datetime NULL,
	[quocTich] Nvarchar(100) NULL,
Primary Key  ([maDaoDien])
) 
go

Create table [Phim_DaoDien] (
	[maPhim] Varchar(10) NOT NULL,
	[maDaoDien] Varchar(10) NOT NULL,
Primary Key  ([maPhim],[maDaoDien])
) 
go


Alter table [DonDatVe] add  foreign key([ID_Khach]) references [ThongTinTaiKhoan] ([ID_Khach]) 
go
Alter table [BinhLuan] add  foreign key([ID_Khach]) references [ThongTinTaiKhoan] ([ID_Khach]) 
go
Alter table [ThongBao] add  foreign key([ID_Khach]) references [ThongTinTaiKhoan] ([ID_Khach]) 
go
Alter table [Phim_TheLoai] add  foreign key([maPhim]) references [Phim] ([maPhim]) 
go
Alter table [Phim_HashTag] add  foreign key([maPhim]) references [Phim] ([maPhim]) 
go
Alter table [LichChieu] add  foreign key([maPhim]) references [Phim] ([maPhim]) 
go
Alter table [BinhLuan] add  foreign key([maPhim]) references [Phim] ([maPhim]) 
go
Alter table [Phim_DienVien] add  foreign key([maPhim]) references [Phim] ([maPhim]) 
go
Alter table [Phim_DaoDien] add  foreign key([maPhim]) references [Phim] ([maPhim]) 
go
Alter table [ThongBao] add  foreign key([maPhim]) references [Phim] ([maPhim]) 
go
Alter table [Phim_TheLoai] add  foreign key([maTheLoai]) references [TheLoai] ([maTheLoai]) 
go
Alter table [Phim_HashTag] add  foreign key([maHashtag]) references [Hashtag] ([maHashtag]) 
go
Alter table [PhongRapPhim] add  foreign key([maRapPhim]) references [RapPhim] ([maRapPhim]) 
go
Alter table [RapPhim_NhanVien] add  foreign key([maRapPhim]) references [RapPhim] ([maRapPhim]) 
go
Alter table [GheNgoi] add  foreign key([maPhong]) references [PhongRapPhim] ([maPhong]) 
go
Alter table [LichChieu] add  foreign key([maPhong]) references [PhongRapPhim] ([maPhong]) 
go
Alter table [VeXemPhim] add  foreign key([maGhe]) references [GheNgoi] ([maGhe]) 
go
Alter table [VeXemPhim] add  foreign key([maLichChieu]) references [LichChieu] ([maLichChieu]) 
go
Alter table [ThongTinThanhToan] add  foreign key([maDonDatVe]) references [DonDatVe] ([maDonDatVe]) 
go
Alter table [VeXemPhim] add  foreign key([maDonDatVe]) references [DonDatVe] ([maDonDatVe]) 
go
Alter table [ThongBao] add  foreign key([maDonDatVe]) references [DonDatVe] ([maDonDatVe]) 
go
Alter table [BinhLuan] add  foreign key([ID_NhanVien]) references [NhanVien] ([ID_NhanVien]) 
go
Alter table [RapPhim_NhanVien] add  foreign key([ID_NhanVien]) references [NhanVien] ([ID_NhanVien]) 
go
Alter table [Phim_DienVien] add  foreign key([maDienVien]) references [DienVien] ([maDienVien]) 
go
Alter table [Phim_DaoDien] add  foreign key([maDaoDien]) references [DaoDien] ([maDaoDien]) 
go


Set quoted_identifier on
go

Set quoted_identifier off
go
