const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Create stations directory if it doesn't exist
const stationsDir = path.join(__dirname, 'stations');
if (!fs.existsSync(stationsDir)) {
    fs.mkdirSync(stationsDir);
}

// Initialize station files if they don't exist
for (let i = 1; i <= 40; i++) {
    const stationFile = path.join(stationsDir, `${i.toString().padStart(2, '0')}.json`);
    if (!fs.existsSync(stationFile)) {
        const defaultData = {
            order_number: "",
            os_version: "",
            notes: ""
        };
        fs.writeFileSync(stationFile, JSON.stringify(defaultData, null, 2));
    }
}

// Get station data
app.get('/station/:id', (req, res) => {
    const stationId = req.params.id.padStart(2, '0');
    const stationFile = path.join(stationsDir, `${stationId}.json`);
    
    try {
        const data = fs.readFileSync(stationFile, 'utf8');
        res.json(JSON.parse(data));
    } catch (err) {
        res.status(404).json({ error: 'Station not found' });
    }
});

// Update station data
app.post('/station/:id', (req, res) => {
    const stationId = req.params.id.padStart(2, '0');
    const stationFile = path.join(stationsDir, `${stationId}.json`);
    
    try {
        fs.writeFileSync(stationFile, JSON.stringify(req.body, null, 2));
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: 'Failed to update station' });
    }
});

const PORT = 17076;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});
