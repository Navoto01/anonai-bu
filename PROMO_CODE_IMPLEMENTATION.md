# AnonLab Pro - Firebase Integration Implementation

## Overview
This implementation removes the local storage of AnonLab Pro status and integrates it with Firebase Realtime Database for proper user-based pro status management with unique, user-specific promo codes.

## Changes Made

### 1. Promo Code System Update
- **Before**: Pro status was stored locally using SharedPreferences with hardcoded promo code
- **After**: Pro status is stored in Firebase Realtime Database with unique promo codes per user

### 2. Firebase Database Structure
The user record in Firebase now includes `anonlabpro`, `anonlabpropromo`, `profileImageUrl`, `username`, and `badgeUrls` fields:
```json
{
  "users": {
    "user_key": {
      "userID": "user_login_id",
      "username": "Display Name",
      "password": "hashed_password",
      "anonlabpro": true/false,
      "anonlabpropromo": "unique_promo_code_for_this_user",
      "profileImageUrl": "https://example.com/path/to/profile/image.jpg",
      "badgeUrls": {
        "0": "./images/badge/private/red-verify.png",
        "1": "./images/badge/wild/6627-agony.png"
      }
    }
  }
}
```

### 3. Key Implementation Details

#### Promo Code Validation
- **No hardcoded promo codes**: Each user has their own unique promo code stored in Firebase
- When a promo code is entered, the system:
  1. Validates the user is logged in
  2. Retrieves the user's record from Firebase
  3. Compares entered code with `anonlabpropromo` field
  4. If match: activates pro and removes the promo code field
  5. Updates local settings for immediate UI refresh
  6. Shows success animation

#### Login Process
- When user logs in successfully:
  1. Retrieves user data from Firebase
  2. Checks `anonlabpro` field value
  3. Updates local settings with Firebase value
  4. Pro status is now synced across devices

#### App Startup
- On app launch, if user is logged in:
  1. Queries Firebase for current user's pro status
  2. Updates local settings to match Firebase
  3. Ensures consistency between Firebase and local state

#### Logout Process
- When user logs out:
  1. Clears login credentials
  2. Resets pro status to false locally
  3. User must re-login to access pro features

#### Profile Image Display
- Account card shows user's profile picture from Firebase `profileImageUrl` field
- If no image URL or loading fails, falls back to letter-based avatar
- Images are loaded asynchronously with loading indicators
- Supports any web-accessible image URL (HTTPS recommended)

#### Username and Badge Display
- Account card displays `username` field instead of `userID` for better user experience
- User badges are loaded from `badgeUrls` array in Firebase
- Maximum 2 badges are displayed next to the username
- Badges support loading states and error fallbacks
- Badge URLs can be relative paths or full URLs

### 4. Platform Compatibility
- **Mobile (iOS/Android)**: Full Firebase integration
- **Desktop (Windows/Linux/macOS)**: Local storage fallback (Firebase not supported)

### 5. Error Handling
- Network errors during Firebase operations
- User not found scenarios
- Invalid promo code validation
- Graceful fallback to non-pro status on errors

## Usage Flow

### For New Users with Promo Code
1. Admin assigns unique promo code to user's Firebase record (`anonlabpropromo` field)
2. User registers account on anon.smstar.hu
3. User logs into AnonAI app
4. User enters their unique promo code in settings
5. System validates code against Firebase record
6. If valid: Pro status is activated and promo code is deleted from Firebase
7. Pro features are immediately available

### For Existing Users
1. User logs into AnonAI app
2. App automatically loads pro status from Firebase
3. If user has pro status, features are enabled
4. Pro status persists across app restarts and device changes

### Admin Workflow
1. Admin adds `anonlabpropromo: "unique_code"` to user's Firebase record
2. User can now redeem this code once
3. After redemption, the promo code field is automatically deleted
4. User cannot use the same code again

## Debug Logging
The implementation includes comprehensive debug logging with emojis for easy identification:
- 🔄 Pro status updates
- 🔑 Login operations
- 🚀 App startup checks
- ✅ Successful Firebase operations
- ❌ Error conditions
- 🖥️ Desktop platform operations
- ⚠️ Warning conditions
- 🚪 Logout operations
- 🖼️ Profile image loading operations

## Security Considerations
- Pro status is tied to user authentication
- Firebase rules should restrict write access to user's own data
- Promo code validation happens client-side (consider server-side validation for production)
- User must be logged in to activate pro features

## Testing
To test the implementation:

### Setup
1. Create a test user account on anon.smstar.hu
2. In Firebase Console, add a complete user record:
   ```json
   {
     "userID": "testuser",
     "username": "Test User",
     "password": "hashedpassword",
     "anonlabpro": false,
     "anonlabpropromo": "TEST_PROMO_123",
     "profileImageUrl": "https://example.com/profile.jpg",
     "badgeUrls": {
       "0": "./images/badge/private/red-verify.png",
       "1": "./images/badge/wild/6627-agony.png"
     }
   }
   ```

### Testing Flow
1. Login to the app with the test user
2. Go to Settings → Pro Card → Promo Code
3. Enter: `TEST_PROMO_123` (or whatever code you set)
4. Verify pro status is activated
5. Check Firebase console to confirm:
   - `anonlabpro: true` is set
   - `anonlabpropromo` field is deleted
6. Logout and login again to verify persistence
7. Try entering the same promo code again - should fail (code no longer exists)

### Error Testing
- Try entering wrong promo code - should show "Invalid promo code"
- Try entering promo code when not logged in - should redirect to login
- Try entering empty promo code - should show validation error

### Profile Image Testing
1. Add a valid image URL to user's `profileImageUrl` field in Firebase
2. Login to the app and check Settings → Account card
3. Should display the profile image instead of letter avatar
4. Try with invalid URL - should fallback to letter avatar
5. Try with no `profileImageUrl` field - should show letter avatar

### Username and Badge Testing
1. Add `username` field to user's Firebase record
2. Add `badgeUrls` object with badge image URLs
3. Login to the app and check Settings → Account card
4. Should display username instead of userID
5. Should show badges next to the username (max 2)
6. Try with invalid badge URLs - should show placeholder badges
7. Try with no badges - should show username without badges