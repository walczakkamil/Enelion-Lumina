import requests
import smtplib
import time
import configparser
import os
import logging
import sqlite3
import sys
from datetime import datetime
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

BASE_IP_PREFIX = "192.168.8."
BASE_URL_TEMPLATE = "http://{ip}/api"
LOGIN_ENDPOINT = "/users/login"
STATUS_ENDPOINT = "/charger/charger"

logger = logging.getLogger("DynamicLogger")
logger.setLevel(logging.INFO)
FORMATTER = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')


def init_db():
    conn = sqlite3.connect('chargers_data.db')
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS energy_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            charger_id TEXT,
            timestamp DATETIME,
            usage_kwh REAL,
            status TEXT
        )
    ''')
    conn.commit()
    conn.close()


def save_to_db(charger_id, usage_kwh, status="OK"):
    try:
        conn = sqlite3.connect('chargers_data.db')
        cursor = conn.cursor()

        current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        cursor.execute('''
            INSERT INTO energy_logs (charger_id, timestamp, usage_kwh, status)
            VALUES (?, ?, ?, ?)
        ''', (charger_id, current_time, usage_kwh, status))

        conn.commit()
    except sqlite3.Error as e:
        print(f"Database error: {e}")
    finally:
        conn.close()


def log_info(charger, message, level=logging.INFO):
    os.makedirs("logs", exist_ok=True)
    log_filename = os.path.join("logs", f"log_{charger}.log")
    #log_filename = f"log_{charger}.log"
    file_handler = logging.FileHandler(log_filename, mode='a', encoding='utf-8')
    file_handler.setFormatter(FORMATTER)
    logger.addHandler(file_handler)

    try:
        logger.log(level, message)
    finally:
        logger.removeHandler(file_handler)
        file_handler.close()


def load_chargers_config(config_path="chargers.ini"):
    config = configparser.ConfigParser()

    if not config.read(config_path):
        raise FileNotFoundError(f"Chargers config file not found: {config_path}")

    chargers = []

    for section in config.sections():
        try:
            charger = {
                "id": int(config[section]["id"]),
                "ip": config[section]["ip"],
                "username": config[section]["username"],
                "password": config[section]["password"],
                "email": config[section].get("email", ""),
                "report_type": config[section].get("report_type", "daily")
            }
            chargers.append(charger)
        except KeyError as e:
            raise Exception(f"Missing key in section [{section}]: {e}")
        except ValueError as e:
            raise Exception(f"Invalid value in section [{section}]: {e}")

    return chargers


def load_email_config(config_path="gmail.ini"):
    config = configparser.ConfigParser()

    if not config.read(config_path):
        print(f"Config file not found: {config_path}, trying environment variables...")

    gmail_user = os.getenv("GMAIL_USER") or config.get("gmail", "user", fallback=None)
    gmail_password = os.getenv("GMAIL_APP_PASSWORD") or config.get("gmail", "app_password", fallback=None)
    summary_email = os.getenv("SUMMARY_EMAIL") or config.get("gmail", "summary_email", fallback=None)

    if not all([gmail_user, gmail_password, summary_email]):
        raise Exception("Missing email configuration (ini or environment variables)")

    return gmail_user, gmail_password, summary_email


def get_charger_data(charger_id, ip, username, password, retries=2):
    base_url = BASE_URL_TEMPLATE.format(ip=ip)
    login_url = base_url + LOGIN_ENDPOINT
    status_url = base_url + STATUS_ENDPOINT

    for attempt in range(retries + 1):
        try:
            with requests.Session() as session:
                payload = {
                    "username": username,
                    "password": password
                }

                print(f"[Charger {charger_id}] Connecting to {ip} (attempt {attempt + 1})...")

                login_response = session.post(login_url, json=payload, timeout=10)
                login_response.raise_for_status()

                try:
                    login_data = login_response.json()
                except ValueError:
                    raise Exception("Invalid login response (not JSON)")

                if not login_data.get("token"):
                    raise Exception("Login failed - no token returned")

                response = session.get(status_url, timeout=10)
                response.raise_for_status()

                try:
                    data = response.json()
                except ValueError:
                    raise Exception("Invalid status response (not JSON)")

                meter_value = data.get("meter_value") or 0
                total_energy = float(meter_value) / 1000  # kWh

                print(f"[Charger {charger_id}] Usage: {total_energy:.2f} kWh")
                return total_energy

        except (requests.exceptions.RequestException, Exception) as e:
            print(f"[Charger {charger_id}] Error: {e}")

            if attempt < retries:
                time.sleep(2)
            else:
                return None


def send_email(gmail_user, gmail_password, recipient, subject, body):
    if not recipient:
        print("Skipping email - empty recipient")
        return

    msg = MIMEMultipart()
    msg["From"] = gmail_user
    msg["To"] = recipient
    msg["Subject"] = subject
    msg.attach(MIMEText(body, "plain"))

    try:
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(gmail_user, gmail_password)
            server.send_message(msg)

        print(f"Email sent to: {recipient}")

    except Exception as e:
        print(f"Email sending error: {e}")


def main():
    now = datetime.now()
    is_first_of_month = (now.day == 1)
    is_first_of_week = (now.weekday() == 0) # Monday

    active_schedules = ["daily"]
    if is_first_of_week:
        active_schedules.append("weekly")
    if is_first_of_month:
        active_schedules.append("monthly")

    manual_collect = len(sys.argv) > 1 and sys.argv[1] == "collect"

    print(f"Active reports today: {active_schedules}")

    init_db()
    try:
        chargers = load_chargers_config()
        gmail_user, gmail_password, summary_email = load_email_config()
    except Exception as e:
        print(f"Config error: {e}")
        return

    summary_report = f"Global Report - {now.strftime('%Y-%m-%d')}\n"
    summary_report += "-----------------------------------\n"

    for charger in chargers:
        usage = get_charger_data(
            charger["id"], charger["ip"],
            charger["username"], charger["password"]
        )
        user_pref = charger.get("report_type", "daily").lower()
        recipient = charger.get("email")

        print("Charger: " + str(charger["id"]))
        print("Schedule: " + user_pref)
        print("E-mail: " + recipient)

        if usage is not None:
            save_to_db(charger['id'], usage, "SUCCESS")
            log_info(charger['id'], f"Usage recorded: {usage:.2f} kWh")

            if not manual_collect and recipient and user_pref in active_schedules:
                subject = f"Charger {charger['id']} - {user_pref.capitalize()} Report"
                body = f"Hello,\n\nYour {user_pref} energy report: {usage:.2f} kWh."
                send_email(gmail_user, gmail_password, recipient, subject, body)

            summary_report += f"Charger {charger['id']}: {usage:.2f} kWh (Pref: {user_pref})\n"
        else:
            save_to_db(charger['id'], 0, "READ_ERROR")
            summary_report += f"Charger {charger['id']}: READ ERROR\n"

            log_info(charger['id'], f"Connection error with {charger['ip']}", level=logging.ERROR)
            if not manual_collect and recipient and user_pref in active_schedules:
                subject = f"Charger {charger['id']} - ERROR"
                error_msg = f"Hello,\n\nWe couldn't reach your charger at {charger['ip']}. Please check connection."
                send_email(gmail_user, gmail_password, recipient, subject, error_msg)

    if not manual_collect and is_first_of_week and is_first_of_month:
        print("Sending global summary...")
        send_email(
            gmail_user, gmail_password, summary_email,
            "GLOBAL Monthly & Weekly Summary", summary_report
        )

    print("\n--- PROCESS COMPLETED ---")


if __name__ == "__main__":
    main()
