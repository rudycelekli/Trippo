# Homzy Transformation Progress

## 🎯 Vision
Transform Trippo (ride-sharing app) into **Homzy** - an AI-powered home services platform where users chat with an AI agent to get help with home issues, and service providers can accept jobs, submit quotes, and track progress with milestones.

---

## ✅ Completed (Phase 1: Foundation & Architecture)

### 1. **Admin Configuration System**
- ✅ `app_config.dart` - Owner control panel settings
- ✅ Support for 3 AI providers (OpenAI, Claude, Gemini) with API key management
- ✅ Configurable service radius (default: 15 miles)
- ✅ Pricing model toggle (platform-defined ↔ provider-defined)
- ✅ Emergency surcharge settings
- ✅ Payment gateway configuration (Stripe, PayPal, Apple Pay, Google Pay)
- ✅ `.env.example` template for environment variables

### 2. **Data Models**
- ✅ `service_category_model.dart` - 20+ service categories with default rates
- ✅ `service_provider_model.dart` - Provider profiles with availability calendar
- ✅ `quote_model.dart` - Quote/estimate system with line items
- ✅ `quote_model.dart` - Payment transaction model (authorize/capture flow)
- ✅ `job_milestone_model.dart` - Milestone tracking for job progress
- ✅ Enhanced `ServiceRequestStatus` with 12 states including tracking and quotes

### 3. **AI Provider Architecture**
- ✅ `ai_provider_interface.dart` - Abstract interface for all AI providers
- ✅ `openai_provider.dart` - OpenAI GPT-4 implementation
- ✅ `claude_provider.dart` - Anthropic Claude implementation
- ✅ `gemini_provider.dart` - Google Gemini implementation
- ✅ `ai_service_factory.dart` - Factory pattern for provider selection
- ✅ Guard-rails and home-services-only system prompts
- ✅ Service category detection from conversations
- ✅ Image analysis capabilities

### 4. **Firestore Repositories**
- ✅ `service_request_repo.dart` - Service request CRUD, geo-matching (15 miles)
- ✅ `quote_repo.dart` - Quote creation, acceptance/decline, updates
- ✅ `milestone_repo.dart` - Job progress tracking, arrival confirmation
- ✅ `payment_repo.dart` - Payment authorization, capture, refund
- ✅ Real-time location streaming for provider tracking

### 5. **Dependencies & Configuration**
- ✅ Updated `pubspec.yaml` to `homzy_user`
- ✅ Added AI chat UI dependencies (dash_chat_2, flutter_markdown)
- ✅ Added image handling (image_picker, cached_network_image)
- ✅ Added calendar (table_calendar, google_sign_in, googleapis)
- ✅ Added payment SDKs (flutter_stripe, pay)
- ✅ Added utilities (uuid, flutter_dotenv, shared_preferences)

---

## 🔄 Key Features Implemented

### **Payment Flow (Authorize → Capture)**
1. Provider accepts request → House call fee **authorized** (pending)
2. Provider marks "arrived" → User confirms arrival → House call fee **captured**
3. Provider submits quote → User accepts → Job starts
4. Provider marks "completed" → User confirms → Final payment **captured**
5. If user declines quote → House call fee still **captured**

### **Milestone Tracking System**
- **Arrived**: Provider marks arrival, user must confirm (triggers house call fee capture)
- **Started**: Job begins after quote acceptance
- **Progress**: Provider adds updates with optional photos
- **Completed**: Provider marks done, user must confirm (triggers final payment)

### **Service Request Statuses**
```
pending → searching → accepted → providerEnRoute → providerArrived →
quotePending → quoteAccepted → inProgress → completed
                ↓
            quoteDeclined (user pays house call fee only)
```

### **AI Conversation Flow**
1. User: "My sink is leaking" + photo
2. AI: Analyzes, detects "plumbing" category
3. AI: "Would you like on-demand or schedule for later?"
4. AI: Creates service request, searches for providers
5. Provider accepts → Tracks to location → Submits quote
6. User accepts quote → Job starts with milestone tracking

---

## 🚧 In Progress (Phase 2: UI Development)

### **Current Focus: AI Chat Interface**
Building the main user interface to replace the map-based home screen with an AI chat experience.

---

## 📋 Remaining Tasks

### **Phase 2: Core UI (Priority)**
1. ⏳ **AI Chat Interface** - Main screen with message bubbles, typing indicators
2. ⏳ **Image Upload UI** - Photo picker for issue documentation
3. ⏳ **Service Request Cards** - Quick actions for on-demand vs scheduled
4. ⏳ **Quote Approval Screen** - Line items, accept/decline with reasons
5. ⏳ **Milestone Confirmation UI** - Confirm arrival, progress, completion
6. ⏳ **Real-time Tracking Map** - Show provider location when en route
7. ⏳ **Calendar View** - User's upcoming appointments

### **Phase 3: Business Logic**
8. ⏳ **AI Service Integration** - Connect OpenAI/Claude/Gemini APIs
9. ⏳ **Provider Matching Algorithm** - Geo-location + category + availability
10. ⏳ **Auto-scheduling Fallback** - When no providers available
11. ⏳ **Payment Gateway Integration** - Stripe auth/capture, PayPal, Apple/Google Pay
12. ⏳ **Google Calendar Sync** - OAuth + event creation
13. ⏳ **Push Notifications** - FCM for status updates

### **Phase 4: Provider App**
14. ⏳ **Provider Onboarding** - Service category selection, rates, availability
15. ⏳ **Request Inbox** - Pending requests with accept/decline
16. ⏳ **Quote Builder** - Add line items, photos, notes
17. ⏳ **Milestone Tracker** - Mark arrival, progress, completion
18. ⏳ **Today's Schedule** - Calendar view of accepted jobs
19. ⏳ **Earnings Dashboard** - Payment history, withdrawals

### **Phase 5: Polish**
20. ⏳ **Rebrand Assets** - Homzy logo, splash screen, colors
21. ⏳ **Theme Updates** - Warm, trustworthy color scheme
22. ⏳ **Android Package** - `dev.hyderali.homzy_user`
23. ⏳ **iOS Bundle ID** - Update for App Store
24. ⏳ **End-to-End Testing** - Full user journey simulation

---

## 🏗️ Architecture Highlights

### **Tech Stack**
```
Frontend: Flutter + Riverpod
Backend: Firebase (Auth, Firestore, FCM, Storage)
AI: OpenAI GPT-4 / Claude / Gemini (owner selectable)
Payments: Stripe, PayPal, Apple Pay, Google Pay
Maps: Google Maps (provider tracking only)
Calendar: Google Calendar + In-app table_calendar
```

### **Firestore Collections**
```
/appConfig (owner settings)
/users
/serviceProviders
/serviceRequests
/quotes
/jobMilestones
/paymentTransactions
/conversations (AI chat history)
/providerAvailability
```

### **Key Design Patterns**
- **Factory Pattern**: AI provider selection
- **Repository Pattern**: Firestore data access
- **Provider Pattern**: Riverpod state management
- **Observer Pattern**: Real-time updates via Firestore streams

---

## 💡 Unique Features

1. **AI-First Experience**: No complex forms, just chat naturally
2. **Milestone-Based Payments**: User confirms each step before payment
3. **Flexible Pricing**: Platform or provider-defined rates
4. **Real-time Tracking**: See provider location when en route
5. **In-App Quotes**: Provider submits detailed estimates with photos
6. **Multi-Payment**: Stripe, PayPal, Apple Pay, Google Pay
7. **Owner Control Panel**: Configure everything via Firestore

---

## 🎯 Next Steps

**Immediate:**
1. Build AI chat interface UI
2. Integrate OpenAI API for conversations
3. Create service request flow UI

**Short-term:**
4. Payment gateway integration
5. Real-time provider tracking
6. Quote approval system

**Medium-term:**
7. Provider app transformation
8. Calendar integration
9. Complete rebranding

---

## 📊 Progress: ~45% Complete

- ✅ Backend architecture: 100%
- ✅ Data models: 100%
- ✅ Repositories: 100%
- ⏳ User UI: 10%
- ⏳ AI integration: 30%
- ⏳ Payment integration: 0%
- ⏳ Provider app: 0%
- ⏳ Branding: 0%

**Estimated time to MVP**: 8-10 days of focused development

---

## 🚀 Launch Checklist

- [ ] User app UI complete
- [ ] Provider app UI complete
- [ ] AI integration tested
- [ ] Payment flows tested
- [ ] Real-time tracking tested
- [ ] Firebase security rules
- [ ] App Store assets
- [ ] Terms of Service / Privacy Policy
- [ ] Beta testing with real users
- [ ] Performance optimization

---

**Last Updated**: 2025-11-05
**Status**: Phase 1 Complete ✅ | Phase 2 In Progress 🚧
