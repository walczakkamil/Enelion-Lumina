import requests
import smtplib
import time
import configparser
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

BASE_IP_PREFIX = "192.168.8."
BASE_URL_TEMPLATE = "http://{ip}/api"
LOGIN_ENDPOINT = "/users/login"
STATUS_ENDPOINT = "/charger/charger"

# Chargers list
CHARGERS = [
    {"id": 65, "ip": 8, "username": "admin", "password": "admin", "email": "user@mail.dot.com"},
]


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
    ip_address = f"{BASE_IP_PREFIX}{ip}"
    base_url = BASE_URL_TEMPLATE.format(ip=ip_address)
    login_url = base_url + LOGIN_ENDPOINT
    status_url = base_url + STATUS_ENDPOINT

    for attempt in range(retries + 1):
        try:
            with requests.Session() as session:
                payload = {
                    "username": username,
                    "password": password
                }

                print(f"[Charger {charger_id}] Connecting to {ip_address} (attempt {attempt + 1})...")

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
    print("\n--- START CHARGER READ ---\n")

    gmail_user, gmail_password, summary_email = load_email_config()

    summary_report = "Energy usage summary:\n\n"

    for charger in CHARGERS:
        usage = get_charger_data(
            charger_id=charger["id"],
            ip=charger["ip"],
            username=charger["username"],
            password=charger["password"]
        )

        if usage is not None:
            record = f"Charger: {charger['id']} | Usage: {usage:.2f} kWh"
            summary_report += record + "\n"

            individual_message = (
                f"Hello,\n\n"
                f"Your charger ({charger['id']}) usage is {usage:.2f} kWh."
            )

            send_email(
                gmail_user,
                gmail_password,
                charger["email"],
                "Charger status",
                individual_message
            )

        else:
            summary_report += f"Charger: {charger['id']} | READ ERROR\n"
            send_email(
                gmail_user,
                gmail_password,
                charger["email"],
                "Charger status",
                "Charger read error..."
            )
    send_email(
        gmail_user,
        gmail_password,
        summary_email,
        "Chargers summary report",
        summary_report
    )

    print("\n--- END ---\n")


if __name__ == "__main__":
    main()