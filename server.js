const express = require('express');
const { Pool } = require('pg');
const multer = require("multer");
const cors = require('cors');
const fs = require("fs");
const path = require("path");
const client = require("pg/lib/client");
const { createClient } = require('@supabase/supabase-js');

// Use the values from Supabase Project Settings

require('dotenv').config();

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY
);

console.log(process.env.SUPABASE_URL);

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
    user: process.env.PGUSER,
    host: process.env.PGHOST,
    password: process.env.PGPASSWORD,
    database: process.env.PGDATABASE,
    port: process.env.PGPORT,
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

pool.connect()
    .then(() => console.log("Connected to PostgreSQL"))
    .catch(err => console.error("DB connection error:", err.stack));


const createTables = `
-- Customers table
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    pending NUMERIC(10,2) DEFAULT 0,
    image TEXT
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    cost NUMERIC(10,2) NOT NULL,
    photo TEXT
);

-- Bills table
CREATE TABLE IF NOT EXISTS bills (
    bill_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(id) ON DELETE CASCADE,
    date TIMESTAMP DEFAULT NOW(),
    name VARCHAR(100) NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    paid NUMERIC(10,2) DEFAULT 0,
    pending NUMERIC(10,2) DEFAULT 0
);

-- Bill items table
CREATE TABLE IF NOT EXISTS bill_items (
    item_id SERIAL PRIMARY KEY,
    bill_id INT REFERENCES bills(bill_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(id) ON DELETE CASCADE,
    quantity INT NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    subtotal NUMERIC(10,2) NOT NULL,
    name VARCHAR(100)
);

`;

(async () => {
  try {
    const client = await pool.connect();
    await client.query(createTables);
    console.log("✅ Tables created successfully");
    client.release();
  } catch (err) {
    console.error("❌ Error creating tables:", err);
  }
})();
//products-db

app.post('/postProducts', async (req, res) => {
    try {
        const { name, cost } = req.body;
        const insertQuery = `
            INSERT INTO products (name, cost)
            VALUES ($1, $2)
                RETURNING *;
        `;
        const result = await pool.query(insertQuery, [name, cost,]);
        console.log(result.rows);
        res.json(result.rows[0]);
    } catch (err) {
        console.error("Error inserting product:", err);
        res.status(500).send("Database error");
    }
});
app.get('/getProduct', async (req, res) => {
    const result = await pool.query("SELECT * FROM products");
    res.json(result.rows);
})

app.delete('/deleteProduct/:id', async (req, res) => {
    const id = req.params.id;
    const result = await pool.query("DELETE FROM products WHERE id = $1", [id]);
    res.send(result.rows);
})

app.put("/updateProduct/:id", async (req, res) => {
    const { id } = req.params;
    const { newname, newcost, newphoto } = req.body;

    try {
        // Check if another product with same name exists
        const exists = await pool.query(
            "SELECT 1 FROM products WHERE name = $1 AND id != $2 LIMIT 1",
            [newname.trim(), id]
        );

        if (exists.rowCount > 0) {
            return res.status(400).json({ error: "Product name already exists" });
        }

        // Update record
        await pool.query(
            "UPDATE products SET name = $1, cost = $2, photo = $3 WHERE id = $4",
            [newname.trim(), newcost, newphoto, id]
        );

        res.status(200).json({ success: true });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Database error" });
    }
});

app.get('/searchProducts', async (req, res) => {
    try {
        const query = req.query.query || "";
        if (!query.trim()) {
            return res.json([]); // no input → empty result
        }

        const result = await pool.query(
            "SELECT id, name FROM products WHERE name ILIKE $1 LIMIT 10",
            [`%${query}%`]
        );

        res.json(result.rows);
    } catch (err) {
        console.error("Search error:", err);
        res.status(500).send("Database error");
    }
});

//customers-db

app.post('/postcustomer', async (req, res) => {
    try {
        const { name, phone, pending } = req.body;
        const insertQuery = `
            INSERT INTO customers (name, phone, pending)
            VALUES ($1, $2, $3)
                RETURNING *;
        `;

        const result = await pool.query(insertQuery, [name, phone, pending]);

        if (result.rows.length === 0) {
            return res.status(404).send("Customer not inserted");
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error("Error inserting customer:", err);
        res.status(500).send("Database error");
    }
});

app.get('/getcustomer', async (req, res) => {
    const result = await pool.query("SELECT * FROM customers");
    res.json(result.rows);
})

app.get('/getCustomerId/:id', async (req, res) => {
    try {
        const result = await pool.query(
            "SELECT * FROM customers WHERE id = $1",
            [req.params.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).send("Customer not found");
        }

        res.json(result.rows[0]); // send customer row as JSON
    } catch (err) {
        console.error("Error fetching customer:", err);
        res.status(500).send("Server error");
    }
});


app.put('/updateCustomer/:id', async (req, res) => {
    try {
        const id = req.params.id;
        const { name, phone, pending } = req.body;

        // 1️⃣ Update customer table
        const result = await pool.query(
            `UPDATE customers
             SET name = $1, phone = $2, pending = $3
             WHERE id = $4
                 RETURNING *`,
            [name, phone, pending, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).send("Customer not found");
        }
        console.log(name,id);
        // 2️⃣ Update bills table to keep customer_name in sync
        await pool.query(
            `UPDATE bills
             SET name = $1
             WHERE customer_id = $2`,
            [name, id]
        );

        res.json(result.rows[0]);
    } catch (err) {
        console.error("Error updating customer:", err);
        res.status(500).send("Error updating data");
    }
});


app.delete('/deleteCustomer/:id', async (req, res) => {
    const id = req.params.id;
    const result = await pool.query("DELETE FROM customers WHERE id = $1", [id]);
    res.send(result.rows);
})

// GET /checkProductName?name=xyz
app.get("/checkProductName", async (req, res) => {
    const { name } = req.query;
    try {
        const result = await pool.query("SELECT 1 FROM products WHERE name = $1 LIMIT 1", [name.trim()]);
        res.json({ exists: result.rowCount > 0 });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Database error" });
    }
});


//bills-db

app.get('/getpending/:id', async (req, res) => {
    try {
        const { id } = req.params;  // ✅ Use params for /:id
        console.log(id);

        const query = 'SELECT SUM(pending) AS pending FROM bills WHERE customer_id = $1';
        const result = await pool.query(query, [id]);

        console.log(result.rows);
        res.json(result.rows[0] || { pending: 0 }); // ✅ return 0 if no rows
    } catch (error) {
        console.error("Error fetching pending:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});


app.get('/getBillId/:id', async (req, res) => {
    try {
        const id = req.params.id;
        const query = 'SELECT * FROM bills WHERE bill_id = $1';
        const result = await pool.query(query, [id]);

        if (result.rows.length === 0) {
            return res.status(404).send("Bill not found");
        }

        res.json(result.rows[0]);  // send single bill as JSON
    } catch (err) {
        console.error("Error fetching bill:", err);
        res.status(500).send("Server error");
    }
});

app.get('/getBillcid/:id', async (req, res) => {
    try {
        const id = req.params.id;
        const query = 'SELECT * FROM bills WHERE customer_id = $1';
        const result = await pool.query(query, [id]);

        if (result.rows.length === 0) {
            return res.status(404).send("Bill not found");
        }

        res.json(result.rows);  // send single bill as JSON
    } catch (err) {
        console.error("Error fetching bill:", err);
        res.status(500).send("Server error");
    }
});

app.delete('/deleteBill/:id', async (req, res) => {
    const bill_id = req.params.id;

    try {
        // Delete items first
        const deleteItemsQuery = 'DELETE FROM bill_items WHERE bill_id = $1';
        await pool.query(deleteItemsQuery, [bill_id]);

        // Then delete the bill itself
        const deleteBillQuery = 'DELETE FROM bills WHERE bill_id = $1';
        await pool.query(deleteBillQuery, [bill_id]);

        // Send success response
        res.status(200).json({ message: `Bill ${bill_id} deleted successfully` });
    } catch (err) {
        console.error('Error deleting bill:', err);
        res.status(500).json({ error: 'Failed to delete bill' });
    }
});

app.post('/postBill/:id', async (req, res) => {
    try {
        const customerId = req.params.id;
        const { name, amount, paid, pending } = req.body;


        const insertQuery = `
      INSERT INTO bills (customer_id, name, amount, paid, pending, date)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING bill_id, date
    `;

        const result = await pool.query(insertQuery, [
            customerId,
            name,
            amount,
            paid,
            pending,
            new Date()
        ]);

        res.json(result.rows[0]);   // ✅ only one response
        console.log(result.rows[0]); // ✅ safe to log
    } catch (err) {
        console.error("Error inserting postBill:", err);
        res.status(500).send("Error creating bill");
    }
});



app.post('/postBillItems/:id', async (req, res) => {
    try {
        const BillId = req.params.id;
        const {product_id,product_name,quantity,unit_cost,subtotal} = req.body;
        const insertQuery = `
            INSERT INTO bill_items (bill_id, product_id, quantity, unit_price, subtotal, name)
            VALUES ($1,$2,$3,$4,$5,$6)
                RETURNING item_id
        `;
        const result = await pool.query(insertQuery, [BillId,product_id,quantity,unit_cost,subtotal,product_name]);
        res.send(result.rows[0]); // returns the newly created bill_id
    } catch (err) {
        console.error("Error inserting postBill:", err);
        res.status(500).send("Error creating bill");
    }
});

app.get('/getBillItemId/:id', async (req, res) => {
    try {

        const id = parseInt(req.params.id, 10);

        const query = `SELECT * FROM bill_items WHERE bill_id = $1`;
        const result = await pool.query(query, [id]);

        if (result.rows.length === 0) {
            return res.status(404).send("No bill items found");
        }

        res.json(result.rows);  // ✅ return entire array
    } catch (err) {
        console.error(err);
        res.status(500).send("Server error");
    }
});

app.put('/updateBill/:id', async (req, res) => {
    try {
        console.log(req.params.id);
        const id = req.params.id;
        const {name, amount, paid, pending, cid} = req.body;

        const result = await pool.query(
            `UPDATE bills
             SET name    = $1,
                 amount  = $2,
                 paid    = $3,
                 pending = $4,
                 customer_id = $5
             WHERE bill_id = $6 RETURNING *`,
            [name, amount, paid, pending, cid, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).send("Product not found");
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error("Error inserting postBill:", err);
        res.status(500).send("Error creating bill");
    }

});

//invoice-db

app.get('/getInvoice', async (req, res) => {
    try {
        const query = `
            SELECT b.*, c.name AS customer_name
            FROM bills b
                     JOIN customers c ON b.customer_id = c.id
            ORDER BY b.date DESC
        `;

        const result = await pool.query(query);

        res.json(result.rows);
        console.log(result.rows);
    } catch (err) {
        console.error("Error fetching invoices:", err);
        res.status(500).send("Error fetching invoices");
    }
});




app.put('/updateBillItems/:billId', async (req, res) => {
    const billId = req.params.billId;
    const items = req.body.items;
    // items = [{ product_id, product_name, unit_cost, quantity, subtotal }, ...]

    try {
        await pool.query('BEGIN');

        // Remove old bill items
        await pool.query('DELETE FROM bill_items WHERE bill_id = $1', [billId]);

        // Insert updated list
        for (const item of items) {
            await pool.query(
                `INSERT INTO bill_items (bill_id, product_id, name, unit_price, quantity, subtotal)
                 VALUES ($1, $2, $3, $4, $5, $6)`,
                [billId, item.product_id, item.product_name, item.unit_cost, item.quantity, item.subtotal]
            );
        }

        await pool.query('COMMIT');
        res.status(200).send({ message: 'Bill items updated successfully!' });
    } catch (err) {
        await pool.query('ROLLBACK');
        console.error('Error updating bill items:', err);
        res.status(500).send('Error updating bill items');
    }
});


// === DB init ===
async function init() {
    await pool.query(`
        CREATE TABLE IF NOT EXISTS goods_entries (
             id SERIAL PRIMARY KEY,
             supplier TEXT NOT NULL,
             date DATE NOT NULL,
             total_cost NUMERIC(12,2) NOT NULL,
            pending_amount NUMERIC(12,2) NOT NULL,
            bill_photo_url TEXT
            );
    `);
    await pool.query(`
        CREATE TABLE IF NOT EXISTS payments (
            id SERIAL PRIMARY KEY,
            entry_id INT NOT NULL REFERENCES goods_entries(id) ON DELETE CASCADE,
            date DATE NOT NULL,
            amount NUMERIC(12,2) NOT NULL
            );
    `);
}
init().catch(console.error);
const upload = multer({ storage: multer.memoryStorage() }); // keep file in memory
require("dotenv").config();

// Upload route to Supabase
app.post("/upload", upload.single("image"), async (req, res) => {
    try {
        const file = req.file;
        if (!file) {
            return res.status(400).json({ error: "No file uploaded" });
        }

        const filename = `${Date.now()}-${file.originalname}`;

        // Upload to Supabase bucket "uploads"
        const { data, error } = await supabase.storage
            .from("uploads")
            .upload(filename, file.buffer, {
                contentType: file.mimetype,
            });

        if (error) {
            console.error("Supabase upload error:", error);
            return res.status(500).json({ error: "Upload failed" });
        }

        // Get public URL
        const { data: publicUrl } = supabase.storage
            .from("uploads")
            .getPublicUrl(filename);

        res.json({ url: publicUrl.publicUrl });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Server error" });
    }
});
// === Routes ===

app.post("/entries", upload.single("billPhoto"), async (req, res) => {
    try {
        const { supplier, date, totalCost } = req.body;
        if (!supplier || !date || totalCost == null) {
            return res.status(400).json({ error: "supplier, date, totalCost required" });
        }

        let billPhotoUrl = null;
        if (req.file) {
            const filename = `${Date.now()}-${req.file.originalname}`;

            // Upload to Supabase bucket "uploads"
            const { error } = await supabase.storage
                .from("uploads")
                .upload(filename, req.file.buffer, {
                    contentType: req.file.mimetype,
                });

            if (error) {
                console.error("Supabase upload error:", error);
                return res.status(500).json({ error: "Upload failed" });
            }

            // Get public URL
            const { data: publicUrl } = supabase.storage
                .from("uploads")
                .getPublicUrl(filename);

            billPhotoUrl = publicUrl.publicUrl;
        }

        const q = `
            INSERT INTO goods_entries (supplier, date, total_cost, pending_amount, bill_photo_url)
            VALUES ($1,$2,$3,$3,$4)
                RETURNING id, supplier, to_char(date,'YYYY-MM-DD') as date,
                total_cost::float AS "totalCost",
                pending_amount::float AS "pendingAmount",
                bill_photo_url AS "billPhotoUrl";
        `;
        const { rows } = await pool.query(q, [supplier, date, totalCost, billPhotoUrl]);
        res.json(rows[0]);
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: "Failed to create entry" });
    }
});


// List entries
app.get("/entries", async (_req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                id,
                supplier,
                to_char(date, 'YYYY-MM-DD') AS date,
        total_cost::float AS "totalcost",
        pending_amount::float AS "pendingamount",
        bill_photo_url AS "billPhotoUrl"
            FROM goods_entries
            ORDER BY date DESC, id DESC
        `);
        console.log(result.rows);
        res.json(result.rows);
    } catch (err) {
        console.error("Error in /entries:", err);
        res.status(500).send("Error fetching entries");
    }
});

// Get payments for entry
app.get("/entries/:id/payments", async (req, res) => {
    try {
        const { id } = req.params;
        const { rows } = await pool.query(
            `SELECT id, entry_id AS "entryId", to_char(date,'YYYY-MM-DD') AS date, amount::float AS amount
             FROM payments WHERE entry_id=$1 ORDER BY date ASC, id ASC`,
            [id]
        );
        res.json(rows);
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: "Failed to fetch payments" });
    }
});

// Add payment
app.post("/entries/:id/payments", async (req, res) => {
    const client = await pool.connect();
    try {
        const { id } = req.params;
        const { date, amount } = req.body;
        const amt = Number(amount);
        if (!date || !amt || amt <= 0) {
            return res.status(400).json({ error: "Valid date and amount required" });
        }

        await client.query("BEGIN");
        const entry = await client.query(
            `SELECT pending_amount FROM goods_entries WHERE id=$1 FOR UPDATE`,
            [id]
        );
        if (!entry.rows.length) {
            await client.query("ROLLBACK");
            return res.status(404).json({ error: "Entry not found" });
        }
        const pending = Number(entry.rows[0].pending_amount);
        if (amt > pending) {
            await client.query("ROLLBACK");
            return res.status(400).json({ error: "Payment exceeds pending amount" });
        }

        await client.query(
            `INSERT INTO payments (entry_id, date, amount) VALUES ($1,$2,$3)`,
            [id, date, amt]
        );
        await client.query(
            `UPDATE goods_entries SET pending_amount = pending_amount - $1 WHERE id=$2`,
            [amt, id]
        );
        await client.query("COMMIT");
        res.status(201).json({ ok: true });
    } catch (e) {
        await client.query("ROLLBACK").catch(() => {});
        console.error(e);
        res.status(500).json({ error: "Failed to add payment" });
    } finally {
        client.release();
    }
});

// Update payment
// PUT /payments/:id
app.put("/payments/:id", async (req, res) => {
    const { id } = req.params;
    const { date, amount } = req.body;

    const client = await pool.connect();
    try {
        await client.query("BEGIN");

        // update payment row
        const updatePayment = await client.query(
            `UPDATE payments SET date=$1, amount=$2 WHERE id=$3 RETURNING entry_id`,
            [date, amount, id]
        );

        if (updatePayment.rows.length === 0) {
            await client.query("ROLLBACK");
            return res.status(404).json({ error: "Payment not found" });
        }

        const entryId = updatePayment.rows[0].entry_id;

        // recalc pending amount
        await client.query(
            `UPDATE goods_entries g
             SET pending_amount = g.total_cost - COALESCE((
                                                              SELECT SUM(amount) FROM payments WHERE entry_id=$1
                                                          ), 0)
             WHERE g.id=$1`,
            [entryId]
        );

        await client.query("COMMIT");
        res.json({ success: true });
    } catch (err) {
        await client.query("ROLLBACK");
        console.error("Error updating payment", err);
        res.status(500).json({ error: "Failed to update payment" });
    } finally {
        client.release();
    }
});

// Delete payment
app.delete("/payments/:id", async (req, res) => {
    const client = await pool.connect();
    try {
        await client.query("BEGIN");

        const { id } = req.params;
        const pay = await client.query(
            `SELECT entry_id, amount FROM payments WHERE id=$1 FOR UPDATE`,
            [id]
        );
        if (!pay.rows.length) {
            await client.query("ROLLBACK");
            return res.status(404).json({ error: "Payment not found" });
        }

        const entryId = pay.rows[0].entry_id;
        const amt = Number(pay.rows[0].amount);

        await client.query(
            `UPDATE goods_entries SET pending_amount = pending_amount + $1 WHERE id=$2`,
            [amt, entryId]
        );

        await client.query(`DELETE FROM payments WHERE id=$1`, [id]);

        await client.query("COMMIT");
        res.json({ ok: true });
    } catch (e) {
        await client.query("ROLLBACK").catch(() => {});
        console.error(e);
        res.status(500).json({ error: "Failed to delete payment" });
    } finally {
        client.release();
    }
});
app.get('/getrevenue', async (req, res) => {
    try {
        const query = 'SELECT SUM(paid) AS total_revenue,sum(pending) AS total_pending FROM bills';
        const result = await pool.query(query);

        // Extract the sum (result.rows[0].total_revenue)
        const revenue = result.rows[0];
        res.json(revenue);
    } catch (err) {
        console.error('Error fetching revenue:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/getsales', async (req, res) => {
    try {
        const query = `
            SELECT COUNT(bill_id) AS sales
            FROM bills
            WHERE (date AT TIME ZONE 'Asia/Kolkata')::date = CURRENT_DATE
        `;
        const result = await pool.query(query);
        res.json(result.rows[0]);
    } catch (err) {
        console.error('Error fetching sales:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});


app.listen(3000, () => console.log("Server running on port 3000"));







