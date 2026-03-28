from fastapi import APIRouter, FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.api.routers.words import router as words_router
from src.settings import settings

app = FastAPI(title=settings.app_name)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors.allowed_origins,
    allow_credentials=True,
    allow_methods=settings.cors.allowed_methods,
    allow_headers=settings.cors.allowed_headers,
)

api_router = APIRouter(prefix="/api")
api_router.include_router(words_router)

app.include_router(api_router)