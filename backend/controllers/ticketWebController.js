const db = require('../config/db');
const fs = require('fs');
const path = require('path');

exports.renderTicket = async (req, res) => {
    try {
        const { ticketCode } = req.params;
        
        const query = `
            SELECT v.mavexemphim as "maVe", v.trangthai,
                   (g.mahangghe || g.soghe) as "tenGhe",
                   p.tenphim as "tenPhim",
                   TO_CHAR(lc.giochieu, 'HH24:MI') as "gioChieu",
                   r.tenrapphim as "tenRapPhim",
                   pr.tenphong as "tenPhong",
                   TO_CHAR(lc.ngaychieu, 'DD/MM/YYYY') as "ngayChieu"
            FROM vexemphim v
            LEFT JOIN ghengoi g ON v.maghe = g.maghe
            JOIN lichchieu lc ON v.malichchieu = lc.malichchieu
            JOIN phim p ON lc.maphim = p.maphim
            JOIN phongrapphim pr ON lc.maphong = pr.maphong
            JOIN rapphim r ON pr.marapphim = r.marapphim
            WHERE v.mavexemphim = $1
        `;
        const result = await db.query(query, [ticketCode]);

        if (result.rows.length === 0) {
            return res.status(404).send('<h1 style="color:white;text-align:center;font-family:sans-serif;">Không tìm thấy vé</h1>');
        }

        const ticket = result.rows[0];
        
        const templatePath = path.join(__dirname, '../views/ticket.html');
        let html = fs.readFileSync(templatePath, 'utf-8');

        html = html.replace('{{TEN_PHIM}}', ticket.tenPhim || '');
        html = html.replace('{{TEN_RAP}}', ticket.tenRapPhim || '');
        html = html.replace('{{NGAY_CHIEU}}', ticket.ngayChieu || '');
        html = html.replace('{{GIO_CHIEU}}', ticket.gioChieu || '');
        html = html.replace('{{TEN_PHONG}}', ticket.tenPhong || '');
        html = html.replace('{{TEN_GHE}}', ticket.tenGhe || '');
        html = html.replace('{{MA_VE}}', ticket.maVe || '');

        let statusClass = 'status-active';
        let statusText = 'VALID';
        if (ticket.trangthai === 'used') {
            statusClass = 'status-used';
            statusText = 'USED';
        } else if (ticket.trangthai === 'expired') {
            statusClass = 'status-expired';
            statusText = 'EXPIRED';
        }

        html = html.replace('{{STATUS_CLASS}}', statusClass);
        html = html.replace('{{STATUS_TEXT}}', statusText);

        res.send(html);
    } catch (error) {
        console.error("Lỗi render vé:", error);
        res.status(500).send('<h1 style="color:white;text-align:center;font-family:sans-serif;">Lỗi server</h1>');
    }
};
