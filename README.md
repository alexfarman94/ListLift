# ListLift

ListLift is an end-to-end prototype that fulfils the PRD for a mobile-first resale listing assistant. This repository contains the SwiftUI iOS app and a FastAPI backend that together cover photo cleanup, attribute extraction, category guidance, pricing comps, AI copy generation, eBay publishing, export kits, notifications, and subscription metering.

## Repository layout

```
.
├── ios/
│   └── ListLiftApp/        # Swift Package with the SwiftUI app sources
├── backend/
│   └── app/                # FastAPI application (routers, services, models)
├── docs/
│   └── architecture.md     # High-level architecture summary
└── README.md
```

## iOS app

* **Technologies:** SwiftUI, Combine, Vision, CoreImage, StoreKit.
* **Features:**
  * Photo capture/import with on-device background removal, auto-enhance, and square crop.
  * OCR label extraction for brand, size, material.
  * Category suggestions and item specifics checklist (blocks publish until completed).
  * Comparable listings with median/IQR price band and filters.
  * AI title/description generator with tone toggles and quality score.
  * eBay OAuth, inventory/offer publish flow, business policies selection.
  * Export kits for Depop, Vinted, Poshmark, Mercari, and Facebook Marketplace.
  * Draft/published tracking, sale detection hooks, plan quotas (Free/Pro/Power).
  * Accessibility-ready UI (Dynamic Type, VoiceOver labels) and EN-UK copy.

Run the app in Xcode 15+ by opening `ios/ListLiftApp` as a Swift Package dependency inside an Xcode project or workspace.

## Backend

* **Technologies:** FastAPI, HTTPX, Pydantic.
* **Endpoints:** Health, pricing comps, AI title generation, category suggestions, item specifics, eBay OAuth/publish, account quotas, sale webhooks.
* **Implementation notes:**
  * Stubbed integrations simulate eBay Sell API flows; swap with live calls for production.
  * Pricing service provides deterministic mock comparables with median/IQR stats.
  * Title generator simulates LLM output with reusable tone templates.
  * In-memory repositories represent persistence for items and accounts (replace with Postgres/Redis).

### Run locally

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

The API will be available at `http://127.0.0.1:8000`. Use tools like `curl` or `HTTPie` to test endpoints.

## Testing

Formal automated tests are not included in this prototype. FastAPI endpoints can be validated quickly with `uvicorn` and manual requests, while SwiftUI previews/Xcode simulators are recommended for the client.

## Next steps

* Replace mocked services with production integrations (eBay API, LLM provider, marketplace exports).
* Persist listings via Core Data + CloudKit, and use a durable backend store.
* Add analytics, crash reporting, and real push notification pipeline.
