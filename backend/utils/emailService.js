const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
    }
});

/**
 * Gửi Email tổng quát
 * @param {string} to - Email người nhận
 * @param {string} subject - Tiêu đề
 * @param {string} html - Nội dung HTML
 */
const sendEmail = async (to, subject, html) => {
    try {
        const mailOptions = {
            from: `"Nhóm 7 Cinema" <${process.env.EMAIL_USER}>`,
            to,
            subject,
            html
        };

        const info = await transporter.sendMail(mailOptions);
        console.log('Email sent: ' + info.response);
        return true;
    } catch (error) {
        console.error('Send Email Error:', error);
        return false;
    }
};

/**
 * Gửi Mã OTP Quên mật khẩu
 */
const sendOTPEmail = async (to, otp) => {
    const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #ddd; border-radius: 10px; overflow: hidden;">
        <div style="background-color: #E51937; color: white; padding: 20px; text-align: center;">
            <h1>Nhóm 7 Cinema</h1>
        </div>
        <div style="padding: 24px; color: #333;">
            <h2>Mã xác thực khôi phục mật khẩu</h2>
            <p>Chào bạn,</p>
            <p>Chúng tôi nhận được yêu cầu khôi phục mật khẩu cho tài khoản của bạn. Vui lòng sử dụng mã OTP dưới đây để hoàn tất quá trình:</p>
            <div style="background-color: #f4f4f4; padding: 16px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #E51937; border-radius: 8px; margin: 24px 0;">
                ${otp}
            </div>
            <p>Mã này có hiệu lực trong <b>5 phút</b>. Nếu bạn không yêu cầu điều này, vui lòng bỏ qua email này.</p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;">
            <p style="font-size: 12px; color: #888; text-align: center;">Đây là email tự động, vui lòng không phản hồi.</p>
        </div>
    </div>
    `;
    return sendEmail(to, 'Mã xác thực OTP - Nhóm 7 Cinema', html);
};

/**
 * Gửi Thông báo đặt vé thành công
 */
const sendBookingSuccessEmail = async (to, bookingDetails) => {
    const { 
        maDonDatVe, 
        tenPhim, 
        ngayChieu, 
        gioChieu, 
        tenRapPhim, 
        tenPhong, 
        seats, 
        tongTien,
        poster_url 
    } = bookingDetails;

    const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #ddd; border-radius: 10px; overflow: hidden;">
        <div style="background-color: #E51937; color: white; padding: 20px; text-align: center;">
            <h1>ĐẶT VÉ THÀNH CÔNG</h1>
        </div>
        <div style="padding: 24px; color: #333;">
            <p>Xin chào,</p>
            <p>Chúc mừng bạn đã đặt vé thành công tại <b>Nhóm 7 Cinema</b>. Dưới đây là thông tin chi tiết đơn hàng của bạn:</p>
            
            <div style="display: flex; background-color: #fafafa; padding: 16px; border-radius: 8px; margin-bottom: 24px;">
                <div style="flex: 1;">
                    <h3 style="color: #E51937; margin-top: 0;">${tenPhim}</h3>
                    <p><b>Mã đơn hàng:</b> ${maDonDatVe}</p>
                    <p><b>Rạp:</b> ${tenRapPhim}</p>
                    <p><b>Phòng:</b> ${tenPhong}</p>
                    <p><b>Suất chiếu:</b> ${gioChieu} - ${ngayChieu}</p>
                    <p><b>Ghế:</b> ${seats.join(', ')}</p>
                    <p style="font-size: 18px;"><b>Tổng cộng:</b> <span style="color: #E51937; font-weight: bold;">${tongTien.toLocaleString('vi-VN')} VNĐ</span></p>
                </div>
            </div>

            <div style="text-align: center; background-color: #fff4f5; padding: 16px; border: 1px dashed #E51937; border-radius: 8px;">
                <p style="margin: 0;">Vui lòng đưa mã đơn hàng hoặc email này cho nhân viên tại quầy để nhận vé.</p>
            </div>

            <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;">
            <p style="font-size: 12px; color: #888; text-align: center;">Chúc bạn có những giây phút xem phim vui vẻ!<br>Đội ngũ Nhóm 7 Cinema.</p>
        </div>
    </div>
    `;
    return sendEmail(to, `Xác nhận đặt vé thành công - #${maDonDatVe}`, html);
};

module.exports = {
    sendOTPEmail,
    sendBookingSuccessEmail
};
