const axios = require('axios');
const crypto = require('crypto');

// --- Cấu hình (Phải khớp với backend) ---
const partnerCode = "MOMO";
const accessKey = "F8BBA842ECF85";
const secretKey = "K951B6PE1waDMi640xX08PD3vg6EkVlz";
const ipnUrl = "https://overall-preschool-nutlike.ngrok-free.dev/api/bookings/momo-ipn";

// Lấy mã đơn hàng từ tham số dòng lệnh
const orderId = process.argv[2];
const amount = process.argv[3] || "275000";

if (!orderId) {
    console.error("Vui lòng nhập mã đơn hàng. VD: node simulate_momo.js DON090568");
    process.exit(1);
}

const requestId = orderId;
const resultCode = 0; // 0 = Thành công
const message = "Success";
const transId = "SIMULATED_" + Date.now();
const orderInfo = "ThanhToanVeXemPhim";
const orderType = "momo_wallet";
const payType = "web";
const responseTime = Date.now().toString();
const extraData = "";

// Tạo chuỗi signature giả lập từ MoMo gửi về
const rawSignature = `accessKey=${accessKey}&amount=${amount}&extraData=${extraData}&message=${message}&orderId=${orderId}&orderInfo=${orderInfo}&orderType=${orderType}&partnerCode=${partnerCode}&payType=${payType}&requestId=${requestId}&responseTime=${responseTime}&resultCode=${resultCode}&transId=${transId}`;

const signature = crypto
    .createHmac('sha256', secretKey)
    .update(rawSignature)
    .digest('hex');

const payload = {
    partnerCode,
    orderId,
    requestId,
    amount,
    orderInfo,
    orderType,
    transId,
    resultCode,
    message,
    payType,
    responseTime,
    extraData,
    signature
};

console.log("--- Đang gửi giả lập thanh toán cho đơn:", orderId, "---");

axios.post(ipnUrl, payload)
    .then(res => {
        console.log("Kết quả từ Server của bạn:", res.status, res.statusText);
        console.log("Chúc mừng! Server đã nhận được thông báo thanh toán.");
    })
    .catch(err => {
        console.error("Lỗi khi gửi giả lập:", err.response ? err.response.data : err.message);
    });
