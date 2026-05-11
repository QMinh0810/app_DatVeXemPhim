const db = require('../backend/config/db');
async function check() {
    try {
        const res = await db.query("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'");
        console.log("Tables in public schema:");
        console.table(res.rows);
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}
check();
