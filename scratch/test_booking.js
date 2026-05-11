const axios = require('axios');

async function testBooking() {
    try {
        // 1. Đăng nhập để lấy token
        console.log('--- Đang đăng nhập ---');
        const loginRes = await axios.post('http://localhost:3000/api/auth/login', {
            username: '0123456789', // Giả sử SĐT này tồn tại
            password: 'password123'
        });
        const token = loginRes.data.token;
        console.log('✅ Đăng nhập thành công');

        // 2. Lấy danh sách lịch chiếu để lấy showtimeId
        console.log('--- Lấy lịch chiếu ---');
        const showtimeRes = await axios.get('http://localhost:3000/api/bookings/showtimes');
        if (showtimeRes.data.data.length === 0) {
            console.log('❌ Không có lịch chiếu nào');
            return;
        }
        const showtimeId = showtimeRes.data.data[0].malichchieu;
        console.log(`✅ Lấy được showtimeId: ${showtimeId}`);

        // 3. Lấy danh sách combo
        console.log('--- Lấy danh sách combo ---');
        const comboRes = await axios.get('http://localhost:3000/api/concessions/combos');
        const comboId = comboRes.data.data[0].combo_id;
        console.log(`✅ Lấy được comboId: ${comboId}`);

        // 4. Thử đặt vé kèm combo
        console.log('--- Thử đặt vé kèm combo ---');
        const bookingRes = await axios.post('http://localhost:3000/api/bookings/book', {
            showtimeId: showtimeId,
            seatIds: ['A1', 'A2'],
            paymentMethod: 'momo',
            concessions: [
                { comboId: comboId, quantity: 1 }
            ]
        }, {
            headers: { Authorization: `Bearer ${token}` }
        });

        console.log('✅ Đặt vé thành công:', bookingRes.data);
    } catch (e) {
        console.error('❌ Lỗi khi đặt vé:', e.response ? e.response.data : e.message);
    }
}

testBooking();
