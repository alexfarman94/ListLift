from __future__ import annotations

from uuid import uuid4
from typing import List

from pydantic import BaseModel


class ListingText(BaseModel):
    id: str
    title: str
    description: str
    tone: str
    quality_score: float


class TitleRequest(BaseModel):
    item_id: str
    tone: str
    brand: str
    size: str
    material: str
    condition: str
    aspects: List[dict]


class TitleGenerator:
    async def generate_titles(self, request: TitleRequest) -> List[ListingText]:
        base_title = f"{request.brand} {request.material} {request.size}"
        descriptors = {
            "seo": ["premium", "authentic", "fast shipping"],
            "concise": ["ready to ship"],
            "vintage": ["retro", "heritage"],
        }
        keywords = descriptors.get(request.tone, [])
        return [
            ListingText(
                id=str(uuid4()),
                title=f"{base_title} {keyword}".strip(),
                description=self._description(request, keyword),
                tone=request.tone,
                quality_score=0.9,
            )
            for keyword in keywords or ["stylish"]
        ]

    def _description(self, request: TitleRequest, keyword: str) -> str:
        specifics = ", ".join(f"{a['name']}: {a['value']}" for a in request.aspects if a.get("value"))
        return (
            f"{request.brand} {request.material} in size {request.size}. Condition: {request.condition}. "
            f"Features {keyword}. {specifics}. Ready to ship from UK."
        )
