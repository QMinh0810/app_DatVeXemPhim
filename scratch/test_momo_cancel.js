const db = require('../backend/config/db');
const axios = require('axios');
const crypto = require('crypto');

async function test() {
    try {
        // 1. Tìm đơn hàng pending
        const orderRes = await db.query("SELECT madondatve, tongtien FROM dondatve WHERE trangthai = 'pending' LIMIT 1");
        if (orderRes.rows.length === 0) {
            console.log("Không tìm thấy đơn hàng pending nào. Hãy tạo một đơn hàng mới trên App.");
            return;
        }
        const { madondatve, tongtien } = orderRes.rows[0];
        console.log(`Đang giả lập hủy cho đơn hàng: ${madondatve}`);

        // 2. Cấu hình MoMo
        const partnerCode = "MOMO";
        const accessKey = "F8BBA842ECF85";
        const secretKey = "K951B6PE1waDMi640xX08PD3vg6EkVlz";
        const ipnUrl = "http://localhost:3000/api/bookings/momo-ipn"; // Test local

        const resultCode = 1006;
        const message = "Transaction denied by user";
        const transId = "CANCELLED_" + Date.now();
        const requestId = madondatve;
        const orderId = madondatve;
        const amount = Math.floor(Number(tongtien)).toString();
        const extraData = "";
        const orderInfo = "ThanhToanVeXemPhim";
        const payType = "web";
        const responseTime = Date.now().toString();

        const rawSignature = `accessKey=${accessKey}&amount=${amount}&extraData=${extraData}&message=${message}&orderId=${orderId}&orderInfo=${orderInfo}&partnerCode=${partnerCode}&payType=${payType}&requestId=${requestId}&responseTime=${responseTime}&resultCode=${resultCode}&transId=${transId}`;

        const signature = crypto
            .createHmac('sha256', secretKey)
            .update(rawSignature)
            .digest('hex');

        const payload = {
            partnerCode, orderId, requestId, amount, orderInfo,
            transId, resultCode, message, payType, responseTime, extraData, signature
        };

        console.log("Gửi Payload:", JSON.stringify(payload, null, 2));

        const response = await axios.post(ipnUrl, payload);
        console.log("Kết quả IPN (HTTP Status):", response.status);

        // Đợi 1 giây để DB cập nhật
        await new Promise(resolve => setTimeout(resolve, 1000));

        // 3. Kiểm tra lại trạng thái trong DB
        const checkRes = await db.query("SELECT trangthai FROM dondatve WHERE madondatve = $1", [madondatve]);
        console.log("Trạng thái đơn hàng sau khi hủy:", checkRes.rows[0].trangthai);

        const checkTicketRes = await db.query("SELECT trangthai FROM vexemphim WHERE madondatve = $1", [madondatve]);
        console.log("Trạng thái vé sau khi hủy:", checkTicketRes.rows[0].trangthai);

        const checkPaymentRes = await db.query("SELECT trangthai, paymentgatewaytransactionid FROM thongtinthanhtoan WHERE madondatve = $1", [madondatve]);
        console.log("Trạng thái thanh toán sau khi hủy:", checkPaymentRes.rows[0].trangthai);
        console.log("Transaction ID ghi nhận:", checkPaymentRes.rows[0].paymentgatewaytransactionid);

    } catch (e) {
        console.error("Lỗi test:", e.response ? e.response.data : e.message);
    } finally {
        process.exit();
    }
}
test();
