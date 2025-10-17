from fastapi import FastAPI, Depends, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional
from uuid import UUID
from datetime import datetime, timedelta

from .services.ebay import EbayClient
from .services.pricing import PricingService
from .services.llm import TitleGenerator
from .models.storage import ItemRepository, AccountRepository

app = FastAPI(title="ListLift API", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

ebay_client = EbayClient()
pricing_service = PricingService(ebay_client)
llm = TitleGenerator()
item_repo = ItemRepository()
account_repo = AccountRepository()


class Aspect(BaseModel):
    id: UUID
    name: str
    value: str
    is_required: bool = Field(alias="isRequired")
    options: List[str]


class ItemModel(BaseModel):
    id: UUID
    brand: str
    size: str
    material: str
    condition: str
    category_id: Optional[str]
    aspects: List[Aspect]


class PricingFilters(BaseModel):
    condition: Optional[str]
    size: Optional[str]
    shipping: Optional[str]
    location: Optional[str]


class PricingRequest(BaseModel):
    item_id: UUID
    category_id: Optional[str]
    condition: str
    filters: PricingFilters


class ComparableListing(BaseModel):
    id: str
    title: str
    price: float
    currency: str
    image_url: Optional[str]
    url: str
    condition: str
    seller_location: str
    shipping_cost: Optional[float]
    marketplace: str


class PriceBand(BaseModel):
    results_count: int
    median: float
    iqr: float
    suggested_min: float
    suggested_max: float
    confidence: str


class PricingSummary(BaseModel):
    items: List[ComparableListing]
    price_band: PriceBand


class TitleRequest(BaseModel):
    item_id: UUID
    tone: str
    brand: str
    size: str
    material: str
    condition: str
    aspects: List[Aspect]


class ListingText(BaseModel):
    id: UUID
    title: str
    description: str
    tone: str
    quality_score: float


class PublishOffer(BaseModel):
    price: float
    quantity: int
    shipping_policy_id: str
    payment_policy_id: str
    return_policy_id: str


class PublishRequest(BaseModel):
    item: ItemModel
    offer: PublishOffer


class PublishResult(BaseModel):
    listing_id: str
    listing_url: str
    status: str


class OAuthTokenRequest(BaseModel):
    code: str


class OAuthRefreshRequest(BaseModel):
    refresh_token: str


@app.get("/api/health")
def health() -> dict:
    return {"status": "ok", "timestamp": datetime.utcnow()}


@app.post("/api/pricing/comps", response_model=PricingSummary)
async def pricing(request: PricingRequest):
    comps = await pricing_service.fetch_comparables(
        brand=request.filters.size,
        condition=request.condition,
        category_id=request.category_id,
        filters=request.filters.dict()
    )
    if not comps.items:
        raise HTTPException(status_code=404, detail="No comparables found")
    return comps


@app.post("/api/titles/generate", response_model=List[ListingText])
async def titles(request: TitleRequest):
    return await llm.generate_titles(request)


@app.post("/api/ebay/oauth/token")
async def oauth_token(request: OAuthTokenRequest):
    return await ebay_client.exchange_code(request.code)


@app.post("/api/ebay/oauth/refresh", response_model=dict)
async def oauth_refresh(request: OAuthRefreshRequest):
    return await ebay_client.refresh_token(request.refresh_token)


@app.post("/api/ebay/publish", response_model=PublishResult)
async def publish(request: PublishRequest, background: BackgroundTasks):
    try:
        result = await ebay_client.publish_listing(request.item, request.offer)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    background.add_task(item_repo.mark_published, request.item.id, result.listing_id)
    return PublishResult(**result.dict())


@app.post("/api/categories/suggest")
async def categories(item: ItemModel) -> List[dict]:
    return await ebay_client.category_suggestions(item)


@app.get("/api/categories/{category_id}/specifics")
async def specifics(category_id: str) -> List[dict]:
    return await ebay_client.item_specifics(category_id)


class SaleNotification(BaseModel):
    item_id: UUID
    order_id: str
    sold_at: datetime


@app.post("/api/ebay/webhook")
async def webhook(payload: dict, background: BackgroundTasks):
    order = ebay_client.parse_webhook(payload)
    if order:
        background.add_task(item_repo.mark_sold, order.item_id, order.order_id)
    return {"status": "accepted"}


class AccountPlan(BaseModel):
    plan: str
    processed_listings: int
    processed_listings_limit: int


@app.get("/api/account/{user_id}", response_model=AccountPlan)
async def account(user_id: UUID):
    account = account_repo.get(user_id)
    return AccountPlan(
        plan=account.plan,
        processed_listings=account.processed_listings,
        processed_listings_limit=account.limit
    )
