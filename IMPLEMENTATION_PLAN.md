# Relay Drivers - Implementation Plan

**Status**: Active Execution Plan
**Last Updated**: 2026-03-09
**Supersedes**: PRD plan file (used for reference)

---

## Execution Order (Fully Featured Driver App)

### PHASE 1: Foundation & Branding (Current)

| Order | Task ID | Feature | Status | Dependencies |
|-------|---------|---------|--------|--------------|
| 1.1 | CPO-DRV-023 | Flutter Project Setup + CI/CD | ✅ DONE | - |
| 1.2 | CPO-DRV-031 | **Relay Branding** - Logo, colors, splash, icons | PENDING | 1.1 |
| 1.3 | CPO-DRV-001 | PWA Shell - manifest.json, service worker | PENDING | 1.2 |
| 1.4 | CPO-DRV-024 | Auth Feature - magic link, session | 🔄 IN PROGRESS | 1.1 |

**Deliverable**: Relay-branded app with working auth

---

### PHASE 2: Driver Onboarding (Core Experience)

| Order | Task ID | Feature | Status | Dependencies |
|-------|---------|---------|--------|--------------|
| 2.1 | CPO-DRV-025 | Profile & Onboarding UI | PENDING | 1.4 |
| 2.2 | CPO-DRV-032 | **Camera Integration** - photo capture | PENDING | 2.1 |
| 2.3 | CPO-DRV-033 | **Reference Image Capture** - selfie for face ID | PENDING | 2.2 |
| 2.4 | CPO-DRV-027 | Document Upload UI - photos + expiry | PENDING | 2.2 |
| 2.5 | CPO-DRV-026 | Vehicle Management UI | PENDING | 2.1 |
| 2.6 | CPO-DRV-004 | **Identity Verification** - Rekognition | PENDING | 2.3 + Backend |

**Deliverable**: Complete driver onboarding with documents, vehicle, face ID

---

### PHASE 3: Job Management

| Order | Task ID | Feature | Status | Dependencies |
|-------|---------|---------|--------|--------------|
| 3.1 | CPO-DRV-002 | Job Management Backend (TDD) | PENDING | - |
| 3.2 | CPO-DRV-003 | Job Management UI | PENDING | 3.1 |
| 3.3 | CPO-DRV-028 | Push Notifications (Firebase) | PENDING | 3.2 |

**Deliverable**: Drivers can accept/decline jobs with push notifications

---

### PHASE 4: Admin & Compliance

| Order | Task ID | Feature | Status | Dependencies |
|-------|---------|---------|--------|--------------|
| 4.1 | CPO-DRV-029 | Admin Compliance Dashboard | PENDING | 2.4 |
| 4.2 | CPO-DRV-030 | Driver Approval Workflow | PENDING | 4.1 |
| 4.3 | CPO-DRV-014 | Operator Approval Flow (explicit) | PENDING | 4.2 |
| 4.4 | CPO-DRV-022 | Audit Trail System | PENDING | 4.2 |

**Deliverable**: Operators can manage driver fleet with compliance indicators

---

### PHASE 5: Future Features (Not Day 1)

| Task ID | Feature | Trigger |
|---------|---------|---------|
| CPO-DRV-007 | Licensing Authority Registry | When 2nd council needed |
| CPO-DRV-008 | Multi-Authority PHV Licenses | When cross-council drivers |
| CPO-DRV-009 | Cross-Tenant Architecture | When 2nd tenant onboards |
| CPO-DRV-010 | Share Token System | When cross-tenant needed |
| CPO-DRV-006 | Location Tracking | When tenant requests GPS |

---

## Feature Details

### Document Upload (CPO-DRV-027 + CPO-DRV-032)

**Required Documents**:
- DVLA Driving License (front + back)
- PHV Badge (council issued)
- PHV Vehicle Plate
- Insurance Certificate
- MOT Certificate (if applicable)
- DBS Certificate
- Right to Work documentation

**Photo Capture Flow**:
1. Select document type
2. Camera opens with document frame overlay
3. Capture photo
4. Review/retake option
5. Enter expiry date
6. Upload to S3 via presigned URL
7. Show pending verification status

**Technical Requirements**:
- `image_picker` package for camera/gallery
- Image compression before upload
- EXIF metadata stripping (privacy)
- S3 presigned URL from backend

---

### Face Recognition (CPO-DRV-033 + CPO-DRV-004)

**Onboarding Flow**:
1. Profile setup complete
2. "Verify Your Identity" screen
3. Face liveness check instructions
4. Camera opens with face oval overlay
5. Capture reference selfie
6. Upload to S3 (encrypted, tenant-isolated)
7. Store reference image key in driver profile

**Verification Flow** (tenant-configurable):
- `onboarding` - First time only
- `daily` - First login each day
- `per_job` - Before each job acceptance
- `random` - 10% of jobs

**AWS Rekognition Integration**:
- Face Liveness API (anti-spoofing)
- CompareFaces API (match vs reference)
- Confidence threshold configurable per tenant

**Backend Requirements**:
- New Lambda: `driver-identity-verification`
- S3 bucket for reference images (encrypted)
- Rekognition service integration

---

### Relay Branding (CPO-DRV-031)

**Brand Assets Needed**:
- Logo (SVG/PNG) - primary + white variant
- App icon (1024x1024 for all sizes)
- Splash screen image
- Color palette (already using Material 3)

**Current Colors** (app_theme.dart):
```dart
primaryColor = Color(0xFF1E3A5F)  // Deep blue
accentColor = Color(0xFF4CAF50)   // Green
```

**PWA Manifest Requirements**:
- 192x192 and 512x512 icons
- Theme color matching brand
- App name: "Relay Drivers"
- Short name: "Relay"

---

## Backend Dependencies

### Existing APIs (Ready to Use)
- `POST /v2/driver/register` - Create driver
- `POST /v2/driver/magic-link` - Request magic link
- `POST /v2/driver/login` - Email/password
- `GET /v2/driver/session` - Validate token
- `GET /v2/driver/profile` - Get profile
- `PUT /v2/driver/profile` - Update profile
- `GET /v2/driver/vehicles` - List vehicles
- `POST /v2/driver/vehicles` - Add vehicle
- `GET /v2/driver/documents` - List documents
- `POST /v2/driver/documents/upload` - Get presigned URL

### New APIs Required
| Endpoint | Lambda | Phase |
|----------|--------|-------|
| `GET /v2/driver/jobs` | driver-jobs | 3 |
| `POST /v2/driver/jobs/{id}/accept` | driver-jobs | 3 |
| `POST /v2/driver/jobs/{id}/decline` | driver-jobs | 3 |
| `PUT /v2/driver/jobs/{id}/status` | driver-jobs | 3 |
| `POST /v2/driver/identity/reference` | driver-identity-verification | 2 |
| `POST /v2/driver/identity/verify` | driver-identity-verification | 2 |

---

## Next Immediate Actions

1. **Complete CPO-DRV-024** - Finish auth (connect to real backend)
2. **Start CPO-DRV-031** - Add Relay branding (logo, colors, splash)
3. **Start CPO-DRV-001** - PWA manifest + service worker
4. **Start CPO-DRV-025** - Profile & Onboarding UI

---

## Success Metrics

### Phase 1-2 Complete (Onboarding)
- [ ] Driver can install PWA from browser
- [ ] Driver can login via magic link
- [ ] Driver can upload all required documents (photos)
- [ ] Driver can add vehicle with photos
- [ ] Driver can capture reference selfie
- [ ] Onboarding progress shows completion %

### Phase 3 Complete (Jobs)
- [ ] Driver receives job offer notification
- [ ] Driver can accept/decline jobs
- [ ] Driver can update job status
- [ ] Job list shows current/completed jobs

### Phase 4 Complete (Compliance)
- [ ] Admin sees driver compliance status (R/A/G)
- [ ] Admin can approve drivers to fleet
- [ ] Expiring documents flagged with warnings
- [ ] Audit trail for all operator actions
