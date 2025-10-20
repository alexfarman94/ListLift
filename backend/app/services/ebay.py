from __future__ import annotations

import os
from uuid import UUID
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta

import httpx
from pydantic import BaseModel

EBAY_BASE = os.getenv("EBAY_BASE", "https://api.ebay.com")


class EbayClient:
    def __init__(self) -> None:
        self.client = httpx.AsyncClient(timeout=15)
        self.client_id = os.getenv("EBAY_CLIENT_ID", "test-client")
        self.client_secret = os.getenv("EBAY_CLIENT_SECRET", "test-secret")
        self.redirect_uri = os.getenv("EBAY_REDIRECT_URI", "listlift://auth")

    async def exchange_code(self, code: str) -> Dict[str, Any]:
        return {
            "access_token": "fake-access-token",
            "refresh_token": "fake-refresh-token",
            "expires_in": 7200,
            "scope": "taxonomy.readonly inventory sell.account",
            "refresh_token_expires_in": 30 * 24 * 3600,
        }

    async def refresh_token(self, refresh_token: str) -> Dict[str, Any]:
        return {
            "access_token": "fake-access-token",
            "refresh_token": refresh_token,
            "expires_at": datetime.utcnow() + timedelta(hours=2),
            "scope": "taxonomy.readonly inventory sell.account",
            "site_id": "EBAY_GB",
        }

    async def publish_listing(self, item: Any, offer: Any) -> "PublishResult":
        if not item.aspects:
            raise ValueError("Item specifics missing")
        listing_id = f"EBAY-{item.id}"
        return PublishResult(
            listing_id=listing_id,
            listing_url=f"https://www.ebay.co.uk/itm/{listing_id}",
            status="published",
        )

    async def category_suggestions(self, item: Any) -> List[Dict[str, Any]]:
        return [
            {
                "categoryId": "11450",
                "categoryPath": "Clothing > Dresses",
                "confidence": 0.82,
            },
            {
                "categoryId": "15724",
                "categoryPath": "Clothing > Tops",
                "confidence": 0.64,
            },
        ]

    async def item_specifics(self, category_id: str) -> List[Dict[str, Any]]:
        return [
            {
                "id": str(UUID(int=1)),
                "name": "Size",
                "value": "",
                "isRequired": True,
                "options": ["XS", "S", "M", "L", "XL"],
            },
            {
                "id": str(UUID(int=2)),
                "name": "Colour",
                "value": "",
                "isRequired": False,
                "options": ["Black", "White", "Blue", "Red"],
            },
        ]

    def parse_webhook(self, payload: Dict[str, Any]) -> Optional["Order"]:
        resource = payload.get("resource")
        if not resource:
            return None
        return Order(
            item_id=UUID(resource.get("itemId")),
            order_id=resource.get("orderId"),
            sold_at=datetime.utcnow(),
        )


class PublishResult(BaseModel):
    listing_id: str
    listing_url: str
    status: str


class Order(BaseModel):
    item_id: UUID
    order_id: str
    sold_at: datetime
