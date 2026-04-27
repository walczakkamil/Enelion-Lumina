# 🔌 Charger Monitoring Script

A simple Python script for monitoring energy usage from network-connected chargers and sending email notifications.

---

## 🚀 Features

* Connects to chargers via REST API
* Authenticates using username/password
* Retrieves energy usage (`meter_value`)
* Sends:

  * 📧 Individual charger status emails
  * 📊 Summary report email
* Handles:

  * Network errors (timeouts, retries)
  * Invalid API responses
  * Missing data
* Configuration via `.ini` file or environment variables

---

## 🧰 Requirements

* Python 3.8+
* Network access to chargers
* Gmail account with **App Password enabled**

Install dependencies:

```bash
pip install requests
```

---

## ⚙️ Configuration

### 1. Create `gmail.ini`

```ini
[gmail]
user = your_email@gmail.com
app_password = your_app_password
summary_email = summary@example.com
```
### 2. Create `chargers.ini`

```ini
[charger_1]
id = 65
ip = 8
username = admin
password = admin
email = user@mails.com

[charger_2]
id = 66
ip = 9
username = admin
password = admin
email = other@mails.com

```


⚠️ **Important:**

* Do NOT use quotes (`"`)
* Use a Gmail **App Password**, not your regular password
* App password must be 16 characters (no spaces)

---

### 2. (Optional) Environment Variables

You can override `.ini` values:

```bash
export GMAIL_USER=your_email@gmail.com
export GMAIL_APP_PASSWORD=your_app_password
export SUMMARY_EMAIL=summary@example.com
```

---

## 🔧 Usage

Run the script:

```bash
python enelion.pl
```

Example output:

```
--- START CHARGER READ ---

[Charger 65] Connecting to 192.168.8.8 (attempt 1)...
[Charger 65] Usage: 12.34 kWh
Email sent to: user@example.com

--- END ---
```

---

## 🔌 Charger Configuration

Edit the `CHARGERS` list in the script:

```python
CHARGERS = [
    {
        "id": 65,
        "ip": 8,
        "username": "admin",
        "password": "admin",
        "email": "user@example.com"
    },
]
```

* `ip` → last octet (used with `BASE_IP_PREFIX`)
* `email` → recipient for individual alerts

---

## 🌐 API Endpoints

The script uses:

* Login: `/api/users/login`
* Status: `/api/charger/charger`

Base URL:

```
http://<IP>/api
```

👉 If your device uses HTTPS:

```python
BASE_URL_TEMPLATE = "https://{ip}/api"
```

---

## ⚠️ Error Handling

The script gracefully handles:

* ❌ Connection timeouts
* ❌ Authentication failures
* ❌ Invalid JSON responses
* ❌ Missing fields

On failure:

* Individual error email is sent
* Summary report includes error entry

---

## 📬 Email Behavior

* Individual email per charger
* One summary email after processing all chargers
* Skips sending if recipient is empty

---

## 🔒 Security Notes

* Do NOT commit `gmail.ini` to GitHub
* Add to `.gitignore`:

```bash
gmail.ini
```

* Prefer environment variables in production

---

## 🛠️ Future Improvements

* HTML email reports
* CSV export / historical tracking
* Docker support
* Scheduling (cron / AWS Lambda)
* Logging instead of `print()`

---

## 📄 License

MIT (or your preferred license)

---

## 👨‍💻 Author

Maintained by Kamil Walczak

---
