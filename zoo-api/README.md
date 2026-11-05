# Zoo API (FastAPI)

Kết nối Oracle thin mode: `localhost:1521/FREEPDB1`, user `ZOO`.

## Chạy

```bash
# từ gốc repo
./scripts/mac/api-dev.sh
# hoặc
cd zoo-api && python3.12 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Swagger: http://localhost:8000/docs

## Demo login

| User | Role | Password |
|---|---|---|
| manager01 | MANAGER | Zoo@123456 |
| vet01 | VET | Zoo@123456 |
| keeper01 | KEEPER | Zoo@123456 |
| cashier01 | CASHIER | Zoo@123456 |
