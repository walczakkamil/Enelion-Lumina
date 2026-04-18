import requests
import json

BASE_IP_PREFIX = "192.168.8."
BASE_URL_TEMPLATE = "http://{ip}/api"
LOGIN_ENDPOINT = "/users/login"
STATUS_ENDPOINT = "/charger/charger"

# Lista ładowarek
CHARGERS = [
    {"mp": 65, "ip": 8, "username": "admin", "password": "admin"},
]


def get_charger_data(mp, ip, username, password):
    ip_address = f"{BASE_IP_PREFIX}{ip}"
    base_url = BASE_URL_TEMPLATE.format(ip=ip_address)
    login_url = base_url + LOGIN_ENDPOINT
    status_url = base_url + STATUS_ENDPOINT

    session = requests.Session()

    try:
        payload = {
            "username": username,
            "password": password
        }

        print(f"[MP {mp}] Logowanie do {ip_address}...")
        login_response = session.post(login_url, json=payload, timeout=10)
        login_response.raise_for_status()

        response = session.get(status_url, timeout=10)
        response.raise_for_status()

        data = response.json()
        total_energy = data.get('meter_value', 0) / 1000  # kWh

        print(f"[MP {mp}] Zużycie: {total_energy:.2f} kWh")

    except requests.exceptions.RequestException as e:
        print(f"[MP {mp}] Błąd: {e}")


def main():
    print("\n--- START ODCZYTU ŁADOWAREK ---\n")

    for charger in CHARGERS:
        get_charger_data(
            mp=charger["mp"],
            ip=charger["ip"],
            username=charger["username"],
            password=charger["password"]
        )

    print("\n--- KONIEC ---\n")


if __name__ == "__main__":
    main()
