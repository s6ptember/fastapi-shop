from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import Dict
from ..database import get_db
from ..services.cart_service import CartService
from ..schemas.cart import CartItemCreate, CartItemUpdate, CartResponse
from pydantic import BaseModel

router = APIRouter(
    prefix="/api/cart",
    tags=["cart"]
)

class AddToCartRequest(BaseModel):
    product_id: int
    quantity: int
    cart: Dict[int, int] = {}

class UpdateCartRequest(BaseModel):
    product_id: int
    quantity: int
    cart: Dict[int, int] = {}

class RemoveFromCartRequest(BaseModel):
    cart: Dict[int, int] = {}

@router.post("/add", status_code=status.HTTP_200_OK)
def add_to_cart(request: AddToCartRequest, db: Session = Depends(get_db)):
    service = CartService(db)
    item = CartItemCreate(product_id=request.product_id, quantity=request.quantity)
    updated_cart = service.add_to_cart(request.cart, item)
    return {"cart": updated_cart}

@router.post("", response_model=CartResponse, status_code=status.HTTP_200_OK)
def get_cart(cart_data: Dict[int, int], db: Session = Depends(get_db)):
    service = CartService(db)
    return service.get_cart_details(cart_data)

@router.put("/update", status_code=status.HTTP_200_OK)
def update_cart_item(request: UpdateCartRequest, db: Session = Depends(get_db)):
    service = CartService(db)
    item = CartItemUpdate(product_id=request.product_id, quantity=request.quantity)
    updated_cart = service.update_cart_item(request.cart, item)
    return {"cart": updated_cart}

@router.delete("/remove/{product_id}", status_code=status.HTTP_200_OK)
def remove_from_cart(product_id: int, request: RemoveFromCartRequest, db: Session = Depends(get_db)):
    service = CartService(db)
    updated_cart = service.remove_from_cart(request.cart, product_id)
    return {"cart": updated_cart}
