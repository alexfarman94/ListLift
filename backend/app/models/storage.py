from __future__ import annotations

from dataclasses import dataclass
from uuid import UUID
from typing import Dict
from datetime import datetime


@dataclass
class ItemRecord:
    item_id: UUID
    listing_id: str | None = None
    sold_at: datetime | None = None


class ItemRepository:
    def __init__(self) -> None:
        self.items: Dict[UUID, ItemRecord] = {}

    async def mark_published(self, item_id: UUID, listing_id: str) -> None:
        self.items[item_id] = ItemRecord(item_id=item_id, listing_id=listing_id)

    async def mark_sold(self, item_id: UUID, order_id: str) -> None:
        record = self.items.get(item_id) or ItemRecord(item_id=item_id)
        record.sold_at = datetime.utcnow()
        self.items[item_id] = record


@dataclass
class AccountRecord:
    user_id: UUID
    plan: str
    processed_listings: int
    limit: int


class AccountRepository:
    def __init__(self) -> None:
        self.records: Dict[UUID, AccountRecord] = {}

    def get(self, user_id: UUID) -> AccountRecord:
        if user_id not in self.records:
            self.records[user_id] = AccountRecord(user_id=user_id, plan="free", processed_listings=0, limit=10)
        return self.records[user_id]
