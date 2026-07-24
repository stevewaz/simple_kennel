# Firebase Email Invite Setup Guide

This guide explains how to set up Firebase Cloud Functions to automatically send invitation emails to staff members.

## Architecture Overview

```
Admin invites staff email
        ↓
Firestore 'invites' collection
        ↓
Cloud Function triggered (onCreate)
        ↓
Email sent via SendGrid
        ↓
Staff clicks link in email
        ↓
App opens with invite code
        ↓
Staff enters invite code + email
        ↓
verifyInviteCode() confirms and creates account
```

## Setup Steps

### 1. **Install Dependencies**

**Firebase Functions:**
```bash
cd functions
npm install nodemailer nodemailer-sendgrid-transport
```

**Flutter App** - Already installed:
- `cloud_firestore`
- `firebase_auth`

### 2. **Set up SendGrid Account**

1. Go to [SendGrid](https://sendgrid.com)
2. Sign up for free account
3. Create API Key:
   - Settings → API Keys → Create API Key
   - Copy the key
4. Set environment variable in Firebase Functions:
   ```bash
   firebase functions:config:set sendgrid.api_key="YOUR_SENDGRID_API_KEY"
   ```

### 3. **Deploy Cloud Functions**

```bash
# From your functions directory
firebase deploy --only functions:sendInviteEmail,functions:verifyInviteCode
```

### 4. **Configure Deep Links**

**For Web:**
- URL: `https://stevewaz.github.io/simple_kennel/?invite=XXXXX`

**For iOS:**
Add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>runbook</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>runbook</string>
    </array>
  </dict>
</array>
```

**For Android:**
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="runbook" android:host="join" />
</intent-filter>
```

### 5. **Firestore Security Rules**

Add to your Firestore rules:
```javascript
match /invites/{document=**} {
  allow read: if false; // Cloud Function only
  allow create: if request.auth.uid != null; // Only authenticated users can create
  allow update, delete: if false; // Cloud Function only
}
```

## Usage Flow

### Step 1: Admin Sends Invite
```dart
// In SettingsScreen - done automatically when email is entered
await authService.inviteStaff(tenantId, 'staff@example.com');
// Cloud Function detects new invite document and sends email
```

### Step 2: Email Sent
Staff member receives email with:
- Invite code: `ABC12345`
- App download links
- Step-by-step instructions
- Clickable deep link

### Step 3: Staff Member Signs Up

**Option A: Click Email Link**
- App opens with `?invite=ABC12345`
- Shows invite code pre-filled
- Staff enters email & password
- Code automatically verified

**Option B: Manual Entry**
- Staff downloads app
- Goes to "Sign Up"
- Clicks "Have an invite code?"
- Enters code + email
- Creates account

### Step 4: Verify Code in App
```dart
// When staff enters code during signup
try {
  final inviteData = await authService.verifyInviteCode(
    inviteCode,
    email,
  );
  final tenantId = inviteData['tenantId'];
  // Complete signup...
} catch (e) {
  // Show error: "Invalid code" or "Expired invite"
}
```

## Firestore Structure

```
invites/
  └── {docId}/
      ├── tenantId: "owner_uid"
      ├── email: "staff@example.com"
      ├── inviteCode: "ABC12345"
      ├── createdAt: timestamp
      ├── expiresAt: timestamp (30 days)
      ├── used: false
      ├── usedAt: null
      └── emailSent: timestamp
```

## Email Template

The Cloud Function sends an HTML email with:
- Company name
- Invite code (large, easy to copy)
- Download links (iOS, Android)
- Clear instructions
- Expiration warning

## Testing

### Local Testing
```bash
# Test Cloud Function locally
firebase emulators:start --only firestore,functions
```

### Test Invite Creation
```dart
// In your app, create a test invite
await FirebaseFirestore.instance.collection('invites').add({
  'tenantId': 'test_tenant',
  'email': 'test@example.com',
  'inviteCode': 'TEST1234',
  'createdAt': DateTime.now(),
  'expiresAt': DateTime.now().add(Duration(days: 30)),
  'used': false,
  'emailSent': null,
});
```

### Verify Email Sent
- Check Firebase Functions logs
- Check SendGrid dashboard for email delivery

## Troubleshooting

### Email not sending
- Check Firebase Functions logs: `firebase functions:log`
- Verify SendGrid API key is set
- Check sender email is verified in SendGrid

### Invite code not verifying
- Ensure email matches exactly
- Check if invite has expired
- Confirm invite hasn't been used already

### Deep links not working
- Verify URL scheme in native config
- Test with: `adb shell am start -a android.intent.action.VIEW -d runbook://join?invite=ABC12345`

## Security Considerations

1. **Invite Codes**: 8 random characters, ~281 trillion combinations
2. **Expiration**: 30 days by default (configurable)
3. **One-time Use**: Marked as `used` after first verification
4. **Email Validation**: User's email must match invited email
5. **Firestore Rules**: Prevents direct reading of invites

## Cost Estimate

- **SendGrid**: Free tier = 100 emails/day, or paid plans
- **Firebase Functions**: Free tier = 2M invocations/month
- **Firestore**: Free tier = 50K reads/day

## Next Steps

1. Set up SendGrid API key
2. Deploy Cloud Functions
3. Configure deep links in native code
4. Test end-to-end invite flow
5. Update signup screen to handle invite codes
