const axios = require('axios');
const crypto = require('crypto');

/**
 * Service xử lý tích hợp MoMo (Môi trường Sandbox)
 */

const createPaymentUrl = async (orderId, amount, orderInfo) => {
    const partnerCode = process.env.MOMO_PARTNER_CODE;
    const accessKey = process.env.MOMO_ACCESS_KEY;
    const secretKey = process.env.MOMO_SECRET_KEY;

    if (!partnerCode || !accessKey || !secretKey) {
        throw new Error("MoMo configuration missing in environment variables");
    }

    const requestId = orderId;
    const requestType = "captureWallet";
    const extraData = "";
    const orderInfoSimple = "ThanhToanVeXemPhim"; // KHÔNG KHOẢNG TRẮNG để tránh lỗi encoding

    const amountStr = amount.toString();
    const redirectUrl = process.env.MOMO_REDIRECT_URL.trim();
    const ipnUrl = process.env.MOMO_IPN_URL.trim();

    // 1. Tạo chuỗi raw signature theo quy định của MoMo (Sắp xếp theo thứ tự bảng chữ cái)
    const rawSignature = `accessKey=${accessKey}&amount=${amountStr}&extraData=${extraData}&ipnUrl=${ipnUrl}&orderId=${orderId}&orderInfo=${orderInfoSimple}&partnerCode=${partnerCode}&redirectUrl=${redirectUrl}&requestId=${requestId}&requestType=${requestType}`;

    // 2. Tạo chữ ký HMAC-SHA256
    const signature = crypto
        .createHmac('sha256', secretKey)
        .update(rawSignature)
        .digest('hex');

    // 3. Chuẩn bị dữ liệu gửi lên MoMo (Chỉ bao gồm các trường có trong signature)
    const requestBody = {
        partnerCode,
        requestId,
        amount: amountStr, // Gửi dưới dạng String
        orderId,
        orderInfo: orderInfoSimple,
        redirectUrl,
        ipnUrl,
        requestType,
        extraData,
        lang: 'vi',
        signature,
    };

    try {
        console.log("--- MOMO REQUEST BODY ---", JSON.stringify(requestBody, null, 2));
        const response = await axios.post(process.env.MOMO_API_URL, requestBody);
        
        if (response.data && response.data.resultCode === 0) {
            return response.data.payUrl; // Đây là link thanh toán MoMo
        } else {
            console.error("MoMo Error Response:", response.data);
            throw new Error(response.data.message || "Lỗi khởi tạo thanh toán MoMo");
        }
    } catch (error) {
        console.error("MoMo Service Error:", error.response ? error.response.data : error.message);
        throw error;
    }
};

/**
 * Hàm xác minh chữ ký từ MoMo gửi về (Redirect hoặc IPN)
 */
const verifySignature = (data) => {
    const { 
        partnerCode = '', 
        orderId = '', 
        requestId = '', 
        amount = '', 
        orderInfo = '', 
        orderType = '', 
        transId = '', 
        resultCode = '', 
        message = '', 
        payType = '', 
        responseTime = '', 
        extraData = '', 
        signature 
    } = data;
    
    const accessKey = process.env.MOMO_ACCESS_KEY;
    const secretKey = process.env.MOMO_SECRET_KEY;

    const rawSignature = `accessKey=${accessKey}&amount=${amount}&extraData=${extraData}&message=${message}&orderId=${orderId}&orderInfo=${orderInfo}&orderType=${orderType}&partnerCode=${partnerCode}&payType=${payType}&requestId=${requestId}&responseTime=${responseTime}&resultCode=${resultCode}&transId=${transId}`;

    console.log("--- MOMO VERIFY SIGNATURE ---");
    console.log("Raw Signature String:", rawSignature);

    const checkSignature = crypto
        .createHmac('sha256', secretKey)
        .update(rawSignature)
        .digest('hex');

    console.log("Calculated Signature:", checkSignature);
    console.log("Received Signature:", signature);

    return checkSignature === signature;
};

module.exports = {
    createPaymentUrl,
    verifySignature
};
