const { VNPay } = require('vnpay');

/**
 * Service xử lý tích hợp VNPay sử dụng thư viện vnpay (lehuygiang28)
 */
const vnpay = new VNPay({
    tmnCode: process.env.VNP_TMN_CODE,
    secureSecret: process.env.VNP_HASH_SECRET,
    vnpayHost: 'https://sandbox.vnpayment.vn',
    testMode: true, // Chế độ test sandbox
});

/**
 * Hàm tạo URL thanh toán
 * @param {string} orderId - Mã đơn hàng (madondatve)
 * @param {number} amount - Số tiền (tongtien)
 * @param {string} orderInfo - Thông tin đơn hàng
 * @param {string} ipAddr - IP người dùng
 * @returns {string} - URL thanh toán VNPay
 */
const buildPaymentUrl = (orderId, amount, orderInfo, ipAddr) => {
    const url = vnpay.buildPaymentUrl({
        vnp_Amount: amount, // Thư viện tự nhân 100
        vnp_IpAddr: ipAddr || '127.0.0.1',
        vnp_TxnRef: orderId,
        vnp_OrderInfo: orderInfo || `Thanh toan ve xem phim ${orderId}`,
        vnp_OrderType: 'other',
        vnp_ReturnUrl: process.env.VNP_RETURN_URL,
    });
    
    console.log("--- VNPAY URL GENERATED ---");
    console.log(url);
    return url;
};

/**
 * Hàm xác minh dữ liệu trả về từ VNPay (Return hoặc IPN)
 * @param {Object} query - Dữ liệu từ VNPay gửi qua query params
 * @returns {Object} - Kết quả xác minh { isSuccess, message, data }
 */
const verifyReturnUrl = (query) => {
    return vnpay.verifyReturnUrl(query);
};

module.exports = {
    vnpay,
    buildPaymentUrl,
    verifyReturnUrl
};
