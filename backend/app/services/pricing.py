from __future__ import annotations

from typing import Dict, Any
from statistics import median
from decimal import Decimal
from uuid import uuid4

from pydantic import BaseModel

from .ebay import EbayClient


class PricingSummary(BaseModel):
    items: list
    price_band: dict


class PricingService:
    def __init__(self, ebay_client: EbayClient) -> None:
        self.ebay_client = ebay_client

    async def fetch_comparables(self, brand: str | None, condition: str, category_id: str | None, filters: Dict[str, Any]) -> PricingSummary:
        listings = self._mock_listings(brand, condition)
        prices = [listing["price"] for listing in listings]
        if not prices:
            return PricingSummary(items=[], price_band=self._band([]))
        return PricingSummary(items=listings, price_band=self._band(prices))

    def _band(self, prices: list[float]) -> dict:
        if not prices:
            return {
                "results_count": 0,
                "median": 0,
                "iqr": 0,
                "suggested_min": 0,
                "suggested_max": 0,
                "confidence": "low",
            }
        prices.sort()
        med = float(median(prices))
        q1 = prices[len(prices) // 4]
        q3 = prices[3 * len(prices) // 4]
        iqr = float(q3 - q1)
        return {
            "results_count": len(prices),
            "median": med,
            "iqr": iqr,
            "suggested_min": float(max(1, med - iqr / 2)),
            "suggested_max": float(med + iqr / 2),
            "confidence": "high" if len(prices) >= 12 else "medium",
        }

    def _mock_listings(self, brand: str | None, condition: str) -> list[dict]:
        base_price = 40 if brand else 30
        multiplier = 1.1 if condition == "newWithTags" else 0.9
        return [
            {
                "id": str(uuid4()),
                "title": f"{brand or 'Item'} #{i}",
                "price": float((base_price + i * 2) * multiplier),
                "currency": "GBP",
                "image_url": None,
                "url": "https://www.ebay.co.uk/itm/demo",
                "condition": condition,
                "seller_location": "UK",
                "shipping_cost": 0,
                "marketplace": "ebay",
            }
            for i in range(1, 16)
        ]
