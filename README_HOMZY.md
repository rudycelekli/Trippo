# 🏠 Homzy - Your AI for Anything Home Care

**Status**: Phase 2 Complete (60% Done) 🚀
**Branch**: `claude/code-review-analysis-011CUoo62Pii7mQzmvduCmRd`

---

## 🎯 What is Homzy?

Homzy transforms home service requests from a complex, form-based process into **natural conversations with AI**.

**Before (Trippo):**
User sees map → Searches for drivers → Books ride → Tracks driver

**After (Homzy):**
User chats with AI → "My sink is leaking" → AI finds plumber → Real-time tracking → Quote approval → Payment

---

## ✅ What's Built So Far

### **Phase 1: Foundation (100% Complete)** ✅
- ✅ Multi-AI provider system (OpenAI, Claude, Gemini)
- ✅ Service category models (20+ home services)
- ✅ Quote/estimate system with line items
- ✅ Milestone-based job tracking
- ✅ Payment authorize/capture flow
- ✅ Service provider models with availability
- ✅ Geo-location provider matching (15-mile radius)
- ✅ 4 Firestore repositories (requests, quotes, milestones, payments)

### **Phase 2: User Interface (100% Complete)** ✅
- ✅ **AI Chat Screen** - Main interface with DashChat 2
- ✅ **Service Dashboard** - Active/Scheduled/History tabs
- ✅ **Real-time Tracking Map** - Live provider location
- ✅ Complete routing system
- ✅ Package rename (trippo_user → homzy_user)
- ✅ Dark theme throughout
- ✅ State management with Riverpod

### **Phase 3: Integration (Pending)** ⏳
- ⏳ Quote approval screen
- ⏳ Milestone confirmation dialogs
- ⏳ AI API integration (OpenAI)
- ⏳ Image upload to Firebase Storage
- ⏳ Payment gateway (Stripe, PayPal, Apple/Google Pay)
- ⏳ Conversation history persistence

### **Phase 4: Provider App (Pending)** ⏳
- ⏳ Provider onboarding & service selection
- ⏳ Request inbox with accept/decline
- ⏳ Quote builder
- ⏳ Milestone tracker
- ⏳ Earnings dashboard

### **Phase 5: Launch (Pending)** ⏳
- ⏳ Complete rebranding (logo, splash screen)
- ⏳ App Store assets
- ⏳ Terms of Service / Privacy Policy
- ⏳ Beta testing

---

## 🚀 Quick Start

### **Setup**

```bash
# 1. Navigate to project
cd trippo_user

# 2. Install dependencies
flutter pub get

# 3. Create environment file
cp ../.env.example .env

# 4. Add your API keys to .env
# - OPENAI_API_KEY
# - STRIPE_PUBLISHABLE_KEY
# - etc.

# 5. Run the app
flutter run
```

### **Firebase Setup**

Ensure Firebase is configured:
```bash
# Android
trippo_user/android/app/google-services.json

# iOS
trippo_user/ios/Runner/GoogleService-Info.plist
```

---

## 📱 User Flow

### **1. Chat with AI**
```
User: "My sink is leaking" + 📸 photo
  ↓
AI: Analyzes image, detects "plumbing"
  ↓
AI: "Would you like on-demand or scheduled?"
  ↓
User: Selects on-demand
```

### **2. Provider Matching**
```
System searches for plumbers within 15 miles
  ↓
Notifications sent to available providers
  ↓
Provider accepts request
```

### **3. Real-time Tracking**
```
Status: Provider En Route 🚗
  ↓
User can track live on map
  ↓
ETA: 15 minutes
```

### **4. Arrival & Payment**
```
Provider marks "Arrived" 📍
  ↓
User confirms arrival
  ↓
House call fee authorized ($XX)
```

### **5. Quote & Job**
```
Provider assesses issue
  ↓
Submits quote with line items
  ↓
User accepts/declines
  ↓
[If accepted] Job starts
  ↓
Provider marks milestones (progress updates)
  ↓
Job complete → User confirms → Final payment
```

---

## 🏗️ Architecture

### **Tech Stack**
```
Frontend:  Flutter + Riverpod
Backend:   Firebase (Auth, Firestore, FCM, Storage)
AI:        OpenAI GPT-4 / Claude / Gemini
Payments:  Stripe, PayPal, Apple Pay, Google Pay
Maps:      Google Maps (tracking only)
Calendar:  Google Calendar + In-app
```

### **Project Structure**
```
trippo_user/lib/
├── config/
│   └── app_config.dart              # Owner settings
├── Model/
│   ├── service_category_model.dart  # 20+ services
│   ├── service_provider_model.dart  # Provider data
│   ├── quote_model.dart             # Quotes & payments
│   └── job_milestone_model.dart     # Progress tracking
├── services/
│   ├── ai_service_factory.dart      # AI provider selection
│   └── ai_providers/
│       ├── openai_provider.dart
│       ├── claude_provider.dart
│       └── gemini_provider.dart
├── Container/Repositories/
│   ├── service_request_repo.dart    # Request CRUD
│   ├── quote_repo.dart              # Quote management
│   ├── milestone_repo.dart          # Job tracking
│   └── payment_repo.dart            # Payments
└── View/Screens/
    ├── Chat_Screen/                 # ⭐ Main UI
    ├── Service_Dashboard/           # Job management
    └── Tracking_Map/                # Live tracking
```

### **Firestore Collections**
```
/appConfig              # Owner settings
/users                  # Homeowners
/serviceProviders       # Service pros
/serviceRequests        # Job requests
/quotes                 # Estimates
/jobMilestones          # Progress tracking
/paymentTransactions    # Payments
/conversations          # Chat history
```

---

## 💡 Key Features

### **1. AI-First Experience**
No complex forms. Just chat naturally:
- "My AC isn't working"
- "I need my lawn mowed"
- "Can you help me organize my garage?"

### **2. Milestone-Based Payments**
User confirms each step before payment:
1. Provider arrives → User confirms → House call fee captured
2. Quote submitted → User accepts → Job starts
3. Job complete → User confirms → Final payment captured

### **3. Flexible Pricing**
- **Platform-defined**: Standard rates for all services
- **Provider-defined**: Providers set own hourly rates
- Toggle via owner settings

### **4. Real-time Everything**
- Live provider location tracking
- Instant status updates
- Push notifications
- Firestore real-time streams

### **5. Multi-Payment Support**
- 💳 Stripe (cards)
- 🅿️ PayPal
- 🍎 Apple Pay
- 🤖 Google Pay

### **6. Owner Control Panel**
Configure everything via Firestore:
- AI provider selection (OpenAI/Claude/Gemini)
- Service radius (default: 15 miles)
- Pricing model toggle
- Emergency surcharge settings
- Platform commission rates

---

## 📊 Progress Tracker

**Overall: 60% Complete**

```
█████████████████████░░░░░░░░░░ 60%
```

| Phase | Status | Progress |
|-------|--------|----------|
| Phase 1: Foundation | ✅ Complete | 100% |
| Phase 2: User UI | ✅ Complete | 100% |
| Phase 3: Integration | ⏳ In Progress | 30% |
| Phase 4: Provider App | ⏳ Pending | 0% |
| Phase 5: Launch Prep | ⏳ Pending | 0% |

---

## 🎨 Design System

### **Colors**
```dart
Primary:    #2196F3  // Actions, CTAs, links
Success:    #4CAF50  // Completed, confirmed
Warning:    #FF9800  // Active, in-progress
Error:      #F44336  // Cancelled, errors
Background: #121212  // App background
Surface:    #1E1E1E  // Cards, containers
```

### **Typography**
- **Font Family**: System default (San Francisco iOS, Roboto Android)
- **Sizes**: 12, 14, 16, 18, 20pt
- **Weights**: Regular (400), Medium (500), Bold (700)

---

## 🧪 Testing

### **Manual Testing**
```bash
# Run on device
flutter run

# Run on iOS simulator
flutter run -d iPhone

# Run on Android emulator
flutter run -d emulator-5554
```

### **Test Scenarios**
1. ✅ Chat screen loads with greeting
2. ✅ Quick action chips send messages
3. ✅ Service dashboard shows empty states
4. ✅ Navigation between screens works
5. ✅ Dark theme consistent throughout
6. ⏳ AI responds to messages (Phase 3)
7. ⏳ Images upload to Firebase (Phase 3)
8. ⏳ Service requests created (Phase 3)
9. ⏳ Payments process (Phase 3)

---

## 📝 Environment Variables

Create `.env` file in project root:

```bash
# AI Provider API Keys
OPENAI_API_KEY=sk-...
CLAUDE_API_KEY=sk-ant-...
GEMINI_API_KEY=...

# Default AI Provider
DEFAULT_AI_PROVIDER=openai

# Payment Gateway
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
PAYPAL_CLIENT_ID=...
PAYPAL_SECRET=...

# Configuration
SERVICE_RADIUS_MILES=15
EMERGENCY_SURCHARGE_ENABLED=true
EMERGENCY_SURCHARGE_PERCENTAGE=50
PRICING_MODEL=platform_defined
```

---

## 🚧 Known Issues

### **Current Limitations:**
1. AI responses are placeholders (need API integration)
2. Image upload doesn't store in Firebase yet
3. Quote approval screen not implemented
4. Milestone confirmations missing
5. Payment flow UI not built
6. Provider app not started

### **To Fix in Phase 3:**
- [ ] Connect OpenAI API for real AI responses
- [ ] Implement Firebase Storage image upload
- [ ] Build quote approval screen
- [ ] Create milestone confirmation dialogs
- [ ] Integrate Stripe payment gateway
- [ ] Persist conversation history

---

## 📚 Documentation

- **Phase 1 Complete**: See `TRANSFORMATION_PROGRESS.md`
- **Phase 2 Complete**: See `PHASE2_COMPLETE.md`
- **Environment Setup**: See `.env.example`
- **API Documentation**: Coming in Phase 3

---

## 🤝 Contributing

### **Code Style**
- Follow Dart style guide
- Use Riverpod for state management
- Keep widgets small and focused
- Add comments for complex logic

### **Git Workflow**
```bash
# Create feature branch
git checkout -b feature/your-feature

# Make changes
git add .
git commit -m "feat: description"

# Push
git push origin feature/your-feature
```

---

## 📞 Support

**Issues**: Open an issue on GitHub
**Questions**: Contact dev team
**Feature Requests**: Submit via GitHub Issues

---

## 🎯 Roadmap

### **Q1 2025**
- ✅ Phase 1: Foundation
- ✅ Phase 2: User UI
- ⏳ Phase 3: Integration (in progress)
- ⏳ Phase 4: Provider App

### **Q2 2025**
- ⏳ Phase 5: Launch Prep
- ⏳ Beta Testing
- ⏳ App Store Submission
- ⏳ Public Launch

---

## 📄 License

Proprietary - All Rights Reserved

---

## 🙏 Credits

**Built with:**
- Flutter & Dart
- Firebase
- Google Maps
- DashChat 2
- Riverpod
- And many more amazing open-source packages!

---

**Version**: 2.0.0-beta
**Last Updated**: 2025-11-05
**Status**: Active Development 🚀

---

*Homzy - Making home care as easy as chatting with a friend* 🏠💬✨
