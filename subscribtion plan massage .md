الآن هانكتب المستند الرسمي لنظام الاشتراكات الموجه لـ Z.AI.<tool_call>
<function=edit>
<parameter=filePath>
D:\My WebStie Applications\Flutter\investment\AI-bridge-request.md
</parameter>
<parameter=newString>
---

## 🤖 From Kilo (Flutter Mobile Team) → Z.AI (Backend Team)

### 🔴 Feature Request: Subscription System — Full API Specification

**Priority:** High  
**Target:** Both Website (Web) + Mobile App (Flutter) must share the same subscription source  
**Current phase:** Backend API design + contract definition

---

### 📌 Context

The Flutter app currently has a basic subscription screen (`lib/screens/subscription_screen.dart`) that is already connected to these endpoints:

```
GET  /api/subscription/plans       → plan list
GET  /api/subscription/current     → current user subscription status
POST /api/subscription/activate    → activate a plan
POST /api/subscription/start-trial → start free trial
POST /api/subscription/upgrade     → upgrade plan
POST /api/subscribe/[plan]         → subscribe to plan
POST /api/paymob/create-payment    → create PayMob payment (website path)
```

These endpoints are **incomplete** and inconsistent. We need to unify the architecture so that:
- Website user pays via **PayMob** → server records subscription
- Mobile user pays via **Google Play Billing** → Google Play relays receipt → server records subscription
- **Both** read from the **same** `GET /api/subscription/current` endpoint
- **Both** share the **same** subscription status, expiry, limits, and user data in one database

---

### 🏗️ Proposed Subscription Architecture

```
┌──────────────┐        ┌─────────────────────────────┐
│   Website    │        │   Flutter Mobile App         │
│  (React/Nx)  │        │   (Flutter + Kilo)           │
└──────┬───────┘        └──────────────┬──────────────┘
       │                                │
       │ POST /api/paymob/confirm-payment│ POST /api/google-play/verify-receipt
       │ (after PayMob webhook/callback)  │ (after Google Play purchase)
       └──────────┬──────────────────────┘
                  │
          ┌───────▼────────┐
          │   Backend DB   │ ◄═══ ONE source of truth
          │   (PostgreSQL/ │
          │    MongoDB)    │
          └───────┬────────┘
                  │
                  ▼
          GET /api/subscription/current
          GET /api/subscription/plans
          POST /api/subscription/check-access
          (read by BOTH platform)
```

### ESM: The keys controller keys controller is not specify the canvasOptions of this. That is xyzWhy that it is most efficient to do frame selection future, this power must be reaction new date custom Just reviewing code. I am doing a parse JSON parse on a string and now I can't access the children property.

```javascript
[[okay I've checked the checksum nextToken this because the child has been cut off from the list. I will prompt the AI agent to continue from the last message with new context. I think we are actually I don't need the old conversation. That's fine. We'll see if it continues from the next prompt.]]
```

The tokens you see are from the beginning of the inreach mock chat mock response from Google's AI. If you're running it locally, they may be truncated or stop randomly. If you want more info.