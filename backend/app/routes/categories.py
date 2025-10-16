from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List
from ..database import get_db
from ..services.category_service import CategoryService
from ..schemas.category import CategoryResponse

router = APIRouter(
    prefix="/api/categories",
    tags=['categories']
)

@router.get("", response_model=List[CategoryResponse], status_code=status.HTTP_200_OK)
def get_categories(db: Session = Depends(get_db)):
    service = CategoryService(get_db)
    return service.get_all_categories()

@router.get('/{category_id}', response_model=CategoryResponse, status_code=status.HTTP_200_OK)
def get_category(category_id: int, db: Session = Depends(get_db)):
    service = CategoryService(db)
    return service.get_category_by_id(category_id)
