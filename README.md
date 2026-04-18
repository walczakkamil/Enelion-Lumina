# 🔌 Charger Energy Reader

Prosty skrypt w Pythonie do odczytu zużycia energii z wielu ładowarek w sieci lokalnej.

## 📋 Opis

Skrypt loguje się do każdej ładowarki poprzez API, pobiera aktualny stan licznika energii (`meter_value`) i wyświetla wynik w konsoli.

Każda ładowarka identyfikowana jest przez:
- **MP (miejsce postojowe)** – identyfikator logiczny
- **IP suffix** – końcówka adresu IP (`192.168.8.X`)
- **username / password** – dane logowania

---

## ⚙️ Wymagania

- Python 3.7+
- Biblioteka `requests`

Instalacja zależności:

```bash
pip install requests
```

---

## 🚀 Uruchomienie

```bash
python main.py
```

---

## 🧩 Konfiguracja

Lista ładowarek znajduje się w zmiennej `CHARGERS`:

```python
CHARGERS = [
    {"mp": 65, "ip": 8, "username": "admin", "password": "admin"},
]
```

### 🔹 Parametry

- `mp` – numer miejsca postojowego (wyświetlany w logach)
- `ip` – końcówka adresu IP (np. `8` → `192.168.8.8`)
- `username` – login do API
- `password` – hasło do API

---

## 📡 Jak to działa

Dla każdej ładowarki skrypt:

1. Buduje adres:
   ```
   http://192.168.8.{ip}/api
   ```
2. Loguje się:
   ```
   POST /users/login
   ```
3. Pobiera dane:
   ```
   GET /charger/charger
   ```
4. Odczytuje `meter_value` i konwertuje na kWh

---

## 🖥️ Przykładowy output

```
--- START ODCZYTU ŁADOWAREK ---

[MP 65] Logowanie do 192.168.8.8...
[MP 65] Zużycie: 12.34 kWh

--- KONIEC ---
```

---

## ⚠️ Obsługa błędów

Jeśli wystąpi problem (np. brak połączenia, timeout, błąd logowania), zostanie wyświetlony komunikat:

```
[MP 65] Błąd: ...
```

---

## 💡 Możliwe rozszerzenia

- zapis wyników do CSV / Excel
- równoległe odpytywanie wielu ładowarek (threading / asyncio)
- integracja z Grafana / Prometheus
- logowanie do pliku
- retry / backoff przy błędach

---

## 📄 Licencja

GNU General Public License v3.0
