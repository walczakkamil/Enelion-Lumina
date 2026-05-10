# 🔌 Enelion Charger Monitoring

A Python-based monitoring tool for collecting energy usage data from Enelion chargers over the local network, storing measurements in SQLite, logging activity, and sending scheduled email reports.

---

## 🚀 Features

- Connects to Enelion chargers via REST API
- Authenticates using charger credentials
- Reads charger energy consumption (`meter_value`)
- Stores historical data in SQLite database
- Writes per-charger logs
- Sends scheduled email reports:
  - Daily
  - Weekly (Mondays)
  - Monthly (1st day of month)
- Sends global summary email
- Supports manual collection mode (data only, no email sending)
- Automatic retries on connection/API failures
- Supports configuration via `.ini` files or environment variables

---

## 📦 Requirements

- Python 3.8+
- Access to charger local network
- Gmail account with App Password enabled

Install dependencies:

```bash
pip install requests
```

---

# ⚙️ Configuration

## Gmail Configuration (`gmail.ini`)

Create:

```ini
[gmail]
user = your_email@gmail.com
app_password = your_16_char_app_password
summary_email = summary@example.com
```

You can also override values with environment variables:

```bash
export GMAIL_USER=your_email@gmail.com
export GMAIL_APP_PASSWORD=your_app_password
export SUMMARY_EMAIL=summary@example.com
```

---

## Charger Configuration (`chargers.ini`)

Example:

```ini
[charger_1]
id = 17
ip = 192.168.8.17
username = admin
password = admin
email = user@example.com
report_type = monthly

[charger_2]
id = 27
ip = 192.168.8.27
username = admin
password = admin
email = other@example.com
report_type = weekly
```

### Parameters

| Field | Description |
|-------|-------------|
| `id` | Charger identifier |
| `ip` | Full charger IP address |
| `username` | Charger login username |
| `password` | Charger login password |
| `email` | Recipient email for reports |
| `report_type` | `daily`, `weekly`, or `monthly` |

---

# 🗄 Database

The script automatically creates:

```text
chargers_data.db
```

Table:

```sql
energy_logs
```

Stored fields:

- Auto ID
- Charger ID
- Timestamp
- Energy usage (kWh)
- Status (`SUCCESS` / `READ_ERROR`)

---

# 📝 Logging

Per-charger logs are stored in:

```text
logs/log_<charger_id>.log
```

Example:

```text
2025-07-01 10:00:00 - INFO - Usage recorded: 12.53 kWh
```

---

# ▶️ Usage

## Normal scheduled execution

```bash
python enelion.pl
```

The script automatically decides active reports:

- Daily → every run
- Weekly → every Monday
- Monthly → first day of month

---

## Manual collection mode

Collect data without sending emails:

```bash
python enelion.pl collect
```

Useful for cron jobs or silent data gathering.

---

# 📧 Email Behavior

## Individual charger reports

Sent only when:

- Charger has recipient email
- Current schedule matches charger `report_type`
- Script is NOT running in manual mode

Example:

**Monthly report charger:**

Sent only on first day of month.

---

## Global summary report

Sent only when:

- It is both:
  - Monday
  - First day of month

Subject:

```text
GLOBAL Monthly & Weekly Summary
```

---

# 🌐 API Endpoints Used

Login:

```text
/api/users/login
```

Status:

```text
/api/charger/charger
```

Base URL:

```text
http://<charger_ip>/api
```

---

# ⚠️ Error Handling

Handles:

- Connection timeout
- Authentication failures
- Invalid JSON responses
- Missing API fields
- SQLite write errors
- Missing configuration files

Failed reads are stored in database as:

```text
READ_ERROR
```

---

# 🔒 Security Notes

Never commit credentials:

Add to `.gitignore`

```gitignore
gmail.ini
chargers.ini
chargers_data.db
logs/
```

Prefer environment variables in production.

---ą

# 🛠 Suggested Deployment

Recommended scheduling via cron:
# 🔌 Charger Monitoring & Reporting Tool

Python-based monitoring tool for Enelion (or compatible) network chargers. The script collects charger energy usage via REST API, stores historical data in SQLite, writes per-charger logs, and sends scheduled email reports.

---

## 🚀 Features

- Connects to chargers over REST API (`/api/users/login`, `/api/charger/charger`)
- Authenticates using charger-specific credentials
- Collects current energy usage (`meter_value`) and converts it to **kWh**
- Stores historical readings in a local **SQLite** database (`chargers_data.db`)
- Creates separate log files per charger in the `logs/` directory
- Sends automatic email reports:
  - **Daily** (default)
  - **Weekly** (every Monday)
  - **Monthly** (1st day of month)
- Sends global summary emails when both weekly and monthly schedules overlap
- Supports manual data collection mode (without sending emails)
- Supports configuration from `.ini` files and environment variables
- Includes retry logic and error handling for unstable network/API responses

---

## 🧰 Requirements

- Python **3.8+**
- Network access to all chargers
- Gmail account with **App Password** enabled (for SMTP email sending)

Install dependencies:

```bash
pip install requests
```

Python standard libraries used (no installation required):
- `sqlite3`
- `configparser`
- `logging`
- `smtplib`
- `datetime`

---

## 📁 Project Structure

```text
.
├── enelion.pl           # Main script
├── chargers.ini         # Charger definitions
├── gmail.ini            # Email configuration (optional if env vars used)
├── chargers_data.db     # Auto-created SQLite database
└── logs/                # Auto-created per-charger log files
```

---

## ⚙️ Configuration

### 1. Configure chargers (`chargers.ini`)

Example:

```ini
[charger_1]
id = 17
ip = 192.168.8.17
username = admin
password = admin
email = user@example.com
report_type = monthly

[charger_2]
id = 27
ip = 192.168.8.27
username = admin
password = admin
email = other@example.com
report_type = weekly
```

#### Supported fields

| Field | Required | Description |
|------|----------|-------------|
| `id` | Yes | Charger identifier / parking space number |
| `ip` | Yes | Full charger IP address |
| `username` | Yes | Charger web/API username |
| `password` | Yes | Charger web/API password |
| `email` | No | Recipient for individual reports |
| `report_type` | No | `daily`, `weekly`, or `monthly` (defaults to `daily`) |

---

### 2. Configure email (`gmail.ini`)

```ini
[gmail]
user = your_email@gmail.com
app_password = your_16_char_app_password
summary_email = summary@example.com
```

> Use a Gmail **App Password**, not your normal Gmail password.

---

### 3. Optional: environment variables

Environment variables override values from `gmail.ini`:

```bash
export GMAIL_USER=your_email@gmail.com
export GMAIL_APP_PASSWORD=your_16_char_app_password
export SUMMARY_EMAIL=summary@example.com
```

---

## ▶️ Usage

### Standard execution

```bash
python enelion.pl
```

Behavior:
- collects data from all configured chargers
- saves results to SQLite
- writes logs
- sends scheduled reports based on `report_type`

---

### Manual collection mode (no emails)

```bash
python enelion.pl collect
```

Useful for:
- testing connectivity
- populating the database manually
- debugging

---

### Recommended scheduling via cron:ą

Daily at 08:00:

```cron
0 8 * * * /usr/bin/python3 /path/to/enelion.pl
```

Silent collection:

```cron
0 * * * * /usr/bin/python3 /path/to/enelion.pl collect
```

## 🗓️ Reporting Logic

| Schedule | Trigger |
|---------|---------|
| Daily | Every run |
| Weekly | Every Monday |
| Monthly | 1st day of month |

A charger receives a report only if its `report_type` matches the active schedule.

Example:
- `report_type = weekly` → email sent only on Mondays
- `report_type = monthly` → email sent only on day 1 of the month

---

## 🗄️ Database

The script automatically creates `chargers_data.db` with table:

```sql
energy_logs (
  id,
  charger_id,
  timestamp,
  usage_kwh,
  status
)
```

Stored statuses:
- `SUCCESS` – data collected successfully
- `READ_ERROR` – charger could not be reached or parsed

---

## 📝 Logging

Logs are stored in:

```text
logs/log_<charger_id>.log
```

Example:

```text
2026-05-10 08:00:01 - INFO - Usage recorded: 14.52 kWh
```

---

## ⚠️ Error Handling

The script handles:

- network timeouts
- authentication failures
- invalid JSON responses
- missing API fields
- missing configuration files
- database write errors

Each failed charger is recorded with status `READ_ERROR`.

---

## 🔐 Security Recommendations

Never commit credentials to source control.

Add to `.gitignore`:

```gitignore
gmail.ini
chargers.ini
chargers_data.db
logs/
```

For production use, prefer environment variables or a secret manager.

---

## 🛠 Future Improvements

- HTML email templates
- CSV/Excel export
- Docker container support
- Cron/systemd service examples
- Dashboard for historical energy usage
- Optional HTTPS support

---

## 📄 License

MIT

---

## 👨‍💻 Author

Maintained by Kamil Walczak


Daily at 08:00:

```cron
0 8 * * * /usr/bin/python3 /path/to/enelion.pl
```

Silent collection:

```cron
0 * * * * /usr/bin/python3 /path/to/enelion.pl collect
```

---

# 📄 License

MIT

---

# 👨‍💻 Author

Maintained by Kamil Walczak