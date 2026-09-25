import requests
import json

url = "https://devapisekolah.eschool.ac.id/api/parent/login"
payload = {
    "email": "081234567900",
    "password": "081234567900"
}
headers = {
    "Content-Type": "application/json"
}

response = requests.post(url, json=payload, headers=headers)
print(json.dumps(response.json(), indent=2))
