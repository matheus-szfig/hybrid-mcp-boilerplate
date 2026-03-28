from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from src.services.words import add_word, clear_words, delete_word, list_words, update_word

router = APIRouter(prefix="/words", tags=["words"])


class WordBody(BaseModel):
    word: str


class UpdateBody(BaseModel):
    old: str
    new: str


@router.get("/", response_model=list[str])
def get_words():
    return list_words()


@router.post("/", response_model=list[str], status_code=201)
def create_word(body: WordBody):
    return add_word(body.word)


@router.put("/", response_model=list[str])
def replace_word(body: UpdateBody):
    try:
        return update_word(body.old, body.new)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.delete("/{word}", response_model=list[str])
def remove_word(word: str):
    try:
        return delete_word(word)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.delete("/", response_model=None, status_code=204)
def remove_all_words():
    clear_words()
