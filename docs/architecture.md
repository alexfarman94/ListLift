# ListLift Architecture Overview

This document summarises the end-to-end ListLift implementation that fulfils the PRD.

## Client (iOS, SwiftUI)

* `AppEnvironment` wires together services such as photo processing, OCR, pricing, and publish workflows.
* Photo processing relies on Apple Vision and CoreImage to perform background removal, auto-crop, and exposure corrections on-device.
* OCR uses Vision text recognition tuned for UK/US English label extraction.
* Category, pricing, and title generation use the backend via an `HTTPClient` with consistent JSON encoding strategies.
* `ListingViewModel` orchestrates the listing flow, maintaining local persistence via `DataStore` (UserDefaults-backed for prototype) and tracking analytics.
* Dedicated view models exist for comparables, title generation, publishing, and dashboards to keep the UI reactive.
* SwiftUI views compose the workflow: capture, clean, attributes, specifics, comps, pricing, AI titles, publish, and export kits.
* Export kits resize images per marketplace and provide copy-ready text plus checklists.
* Billing integrates with StoreKit to enforce plan quotas and drive upgrades.
* Accessibility and localisation hooks (Dynamic Type, VoiceOver labels, currency formatting) are applied throughout.

## Backend (FastAPI)

* Provides endpoints for category suggestions, item specifics, pricing comparables, title generation, eBay OAuth token exchange, publishing, account plans, and sale webhooks.
* `EbayClient` encapsulates eBay API interactions (stubbed with deterministic responses for now) and ensures publish flow alignment with Sell APIs.
* `PricingService` calculates mock comparable data and derives a price band with median/IQR.
* `TitleGenerator` simulates AI-generated title/description variants.
* In-memory repositories (`ItemRepository`, `AccountRepository`) store publish/sale state and quota counters; swap for Postgres in production.
* Webhook handler acknowledges sale events and flags items as sold to power delist nudges.

## Future Work

* Replace stubbed services with live eBay, Etsy, and marketplace integrations.
* Persist data in Core Data (client) and Postgres (backend).
* Harden auth, add monitoring, implement remote notifications, and expand analytics.
