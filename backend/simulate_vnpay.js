const axios = require('axios');
const crypto = require('crypto');
const queryString = require('query-string');

// --- Cấu hình (Phải khớp với backend .env) ---
const tmnCode = "QJIB6FOE";
const secretKey = "HDI2PVAS8J0KTV4810TVJ7MYOSBGW76J";
const ipnUrl = "https://overall-preschool-nutlike.ngrok-free.dev/api/bookings/vnpay-ipn";

const orderId = process.argv[2];
const amount = process.argv[3] || "275000";

if (!orderId) {
    console.error("Vui lòng nhập mã đơn hàng. VD: node simulate_vnpay.js DON090568");
    process.exit(1);
}

// Giả lập dữ liệu VNPay gửi về
let vnp_Params = {
    vnp_TmnCode: tmnCode,
    vnp_Amount: (parseInt(amount) * 100).toString(),
    vnp_Command: 'pay',
    vnp_CreateDate: '20240512120000',
    vnp_CurrCode: 'VND',
    vnp_IpAddr: '127.0.0.1',
    vnp_Locale: 'vn',
    vnp_OrderInfo: 'Thanh toan ve xem phim ' + orderId,
    vnp_OrderType: 'other',
    vnp_ReturnUrl: 'http://localhost:3000/api/bookings/vnpay-return',
    vnp_TxnRef: orderId,
    vnp_Version: '2.1.0',
    vnp_ResponseCode: '00',
    vnp_TransactionNo: '12345678',
    vnp_BankCode: 'NCB',
    vnp_PayDate: '20240512120500',
    vnp_TransactionStatus: '00'
};

// Sắp xếp params theo alphabet
vnp_Params = Object.keys(vnp_Params)
    .sort()
    .reduce((obj, key) => {
        obj[key] = vnp_Params[key];
        return obj;
    }, {});

const signData = queryString.stringify(vnp_Params, { encode: false });
const hmac = crypto.createHmac("sha512", secretKey);
const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest("hex");

vnp_Params['vnp_SecureHash'] = signed;

const finalUrl = `${ipnUrl}?${queryString.stringify(vnp_Params, { encode: false })}`;

console.log("--- Đang gửi giả lập VNPay IPN cho đơn:", orderId, "---");

axios.get(finalUrl)
    .then(res => {
        console.log("Kết quả từ Server:", res.data);
    })
    .catch(err => {
        console.error("Lỗi:", err.response ? err.response.data : err.message);
    });
