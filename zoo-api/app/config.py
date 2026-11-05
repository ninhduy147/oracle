"""Cấu hình API — đọc từ .env ở thư mục gốc repo."""
from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

ROOT = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(ROOT / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    oracle_host: str = "localhost"
    oracle_port: int = 1521
    oracle_service: str = "FREEPDB1"
    oracle_user: str = "ZOO"
    oracle_password_zoo: str = "ZooApp_Demo1"

    api_host: str = "0.0.0.0"
    api_port: int = 8000
    jwt_secret: str = "doi_chuoi_nay_bang_chuoi_ngau_nhien_dai"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 480
    cors_origins: str = "http://localhost:5173,http://127.0.0.1:5173"
    bcrypt_rounds: int = 12

    @property
    def dsn(self) -> str:
        return f"{self.oracle_host}:{self.oracle_port}/{self.oracle_service}"

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
