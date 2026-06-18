const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const app = express();
app.use(express.json());

const db = new sqlite3.Database('./app_data.db');
const timestamp = new Date().toISOString();

// Initialize Database
db.serialize(() => {
    db.run("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, login TEXT UNIQUE, password TEXT)");
    
    // Scans table
    db.run(`CREATE TABLE IF NOT EXISTS scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_login TEXT, 
        id_ttn TEXT, 
        driver_name TEXT, 
        id_car TEXT, 
        field_name TEXT, 
        field_id TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // Fields table
    db.run("CREATE TABLE IF NOT EXISTS fields (id TEXT PRIMARY KEY, name TEXT)");

    // Seed 10 fields if empty
    db.get("SELECT COUNT(*) as count FROM fields", [], (err, row) => {
        if (err || row.count === 0) {
            const fields = [
                ['1', 'Урочище Південне'], ['2', 'Урочище Північне'], ['3', 'Поле Західне'],
                ['4', 'Поле Східне'], ['5', 'Нива 1'], ['6', 'Нива 2'],
                ['7', 'Балка'], ['8', 'Яр'], ['9', 'Околиця'], ['10', 'Центральне']
            ];
            const stmt = db.prepare("INSERT INTO fields (id, name) VALUES (?, ?)");
            fields.forEach(f => stmt.run(f));
            stmt.finalize();
        }
    });
});

// API: Save Scan (The endpoint Flutter calls via kApiSubmit)
app.post('/scan', (req, res) => {
    const { login, id_ttn, driver_name, id_car, field_name, field_id } = req.body;

    const sql = `INSERT INTO scans (user_login, id_ttn, driver_name, id_car, field_name, field_id) VALUES (?, ?, ?, ?, ?, ?)`;
    
    db.run(sql, [login, id_ttn, driver_name, id_car, field_name, field_id], (err) => {
        if (err) {
            console.error("Database insert error:", err);
            return res.status(500).send("Database error");
        }
        res.status(200).send({ status: "success" });
    });
});

// API: Get List (The endpoint Flutter calls via kApiList)
app.post('/list', (req, res) => {
    const { login } = req.body;
    db.all("SELECT * FROM scans WHERE user_login = ? ORDER BY timestamp DESC", [login], (err, rows) => {
        if (err) return res.status(500).send("Database error");
        res.json(rows);
    });
});

// API: Get Fields (The endpoint Flutter calls via kApiFields)
app.post('/fields', (req, res) => {
    db.all("SELECT * FROM fields", [], (err, rows) => {
        if (err) return res.status(500).send("Database error");
        res.json(rows);
    });
});

app.listen(3000, () => console.log('Backend running on http://localhost:3000'));