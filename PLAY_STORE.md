# Google Play Store — Complete Publishing Guide for My Reading Town

This guide walks you through every step needed to go from zero to a published app with real in-app purchases on the Google Play Store. Follow the steps in order.

---

## PART 1 — Create a Google Play Developer Account

### Step 1.1 — Sign in to Google Play Console

1. Open https://play.google.com/console
2. Sign in with the Google account you want to use as your developer identity (use a permanent account, not a temporary one).

### Step 1.2 — Pay the One-Time Registration Fee

1. Click **"Get started"** or **"Create developer account"**.
2. You will be asked to pay a **one-time $25 USD registration fee**.
3. Pay with a credit or debit card (Google Pay is accepted).
4. The fee is non-refundable and grants you a permanent developer account.

### Step 1.3 — Complete Your Account Profile

1. Fill in:
   - **Developer name** — this appears publicly on the Play Store (e.g., "Fernando Pinto Studios").
   - **Email address** — visible to users who contact you (use a real one).
   - **Website** (optional but recommended).
   - **Phone number** (required for 2-factor authentication).
2. Accept the **Google Play Developer Distribution Agreement**.
3. Your account is now active. It may take up to 48 hours before you can publish apps.

---

## PART 2 — Prepare the App for the Play Store

### Step 2.1 — Configure App Identity

Edit `my_reading_town/pubspec.yaml`:

```yaml
name: my_reading_town
version: 1.0.0+1   # format: version_name+version_code
```

- `version_name` (e.g., `1.0.0`) is shown to users.
- `version_code` (e.g., `1`) is an integer used internally by Google. It must increase with every upload.

Edit `my_reading_town/android/app/build.gradle` and set:

```gradle
android {
    defaultConfig {
        applicationId "com.ferchostudios_dev.my_reading_town"   // CHANGE THIS — must be unique on the Play Store
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

**Important:** `applicationId` must be globally unique. Reverse-domain notation is standard (e.g., `com.fernandopinto.myreadingtown`).

### Step 2.2 — Generate a Signing Key

You must sign your release APK/AAB with a keystore file. Run this **once** and keep the file safe:

```bash
keytool -genkey -v \
  -keystore ~/my-reading-town-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias my-reading-town
```

You will be asked for a password and your name/organization. **Never lose this file** — you cannot update your app without it.

### Step 2.3 — Configure Signing in Flutter

Create `my_reading_town/android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=my-reading-town
storeFile=/home/youruser/my-reading-town-release.jks
```

Edit `my_reading_town/android/app/build.gradle` to use the keystore:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

**Add `key.properties` to `.gitignore`** — never commit it.

### Step 2.4 — Build the Release AAB

Google Play requires an **Android App Bundle (.aab)**, not an APK:

```bash
cd my_reading_town
flutter build appbundle --release
```

The output file will be at:
`my_reading_town/build/app/outputs/bundle/release/app-release.aab`

---

## PART 3 — Create the App in Play Console

### Step 3.1 — Create a New App

1. In Play Console, click **"Create app"**.
2. Fill in:
   - **App name**: My Reading Town
   - **Default language**: English (United States)
   - **App or game**: Game
   - **Free or paid**: Free (you earn through in-app purchases)
3. Accept the declarations and click **"Create app"**.

### Step 3.2 — Complete the Store Listing

Go to **Grow > Store presence > Main store listing**:

- **App name**: My Reading Town
- **Short description** (max 80 chars): Build your reading village! Read books, earn resources, grow your town.
- **Full description** (max 4000 chars): Write a compelling description of the game.
- **Screenshots**: At least 2 phone screenshots (1080×1920 px recommended).
- **Feature graphic**: 1024×500 px banner image.
- **App icon**: 512×512 px PNG (already set up via flutter_launcher_icons).

### Step 3.3 — Content Rating

Go to **Policy > App content > Content rating**:

1. Click **"Start questionnaire"**.
2. Answer questions about your app's content (no violence, no explicit content).
3. You will likely receive a **"Everyone"** or **"Everyone 10+"** rating.

### Step 3.4 — Target Audience

Go to **Policy > App content > Target audience and content**:

- Select age ranges your app targets (e.g., 13+, or if suitable for children, you must comply with COPPA).

### Step 3.5 — Privacy Policy

You need a Privacy Policy URL. You can:
1. Create a simple one at https://app-privacy-policy-generator.firebaseapp.com/
2. Host it on GitHub Pages or any simple web server.
3. Paste the URL in **Policy > App content > Privacy policy**.

---

## PART 4 — Register In-App Products

This is critical for the store to work. All products sold with real money must be registered here.

### Step 4.1 — Enable In-App Purchases

Go to **Monetize > Products > In-app products**.

If this section is greyed out, you may need to:
1. Upload at least one APK/AAB to a testing track first (see Part 5).
2. Have a valid payment profile linked to your Play Console account.

To set up a payment profile: click your account name > **Payments profile** and add a bank account.

### Step 4.2 — Register Gems Products (Consumable)

For each gem pack, click **"Create product"**:

| Product ID     | Name                | Description            | Price    |
|---------------|---------------------|------------------------|----------|
| `gems_50`     | 50 Gems             | 50 gems for your town  | $0.99    |
| `gems_100`    | 100 Gems            | 100 gems for your town | $1.99    |
| `gems_200`    | 200 Gems            | 200 gems for your town | $3.99    |
| `gems_500`    | 500 Gems            | 500 gems for your town | $8.99    |
| `gems_1000`   | 1000 Gems           | 1000 gems for your town| $16.99   |
| `gems_2000`   | 2000 Gems           | 2000 gems for your town| $29.99   |

For each product:
1. Set **Product ID** exactly as shown (must match the `productId` in `store_rules.dart`).
2. Set **Type** to **"Consumable"** (gems can be bought multiple times).
3. Set **Status** to **Active**.
4. Set the price.
5. Click **Save**.

### Step 4.3 — Register Pack Products (Consumable)

| Product ID      | Name          | Description                             | Price    |
|----------------|---------------|-----------------------------------------|----------|
| `pack_starter` | Starter Pack  | 50 coins + 30 wood + 10 metal + 1 sandwich | $1.49 |
| `pack_builder` | Builder Pack  | 100 coins + 100 wood + 50 metal + 2 hammers | $2.99 |
| `pack_reader`  | Reader Pack   | 200 coins + 50 gems + 3 books + 3 glasses | $4.99  |
| `pack_town`    | Town Pack     | 500 coins + 200 wood + 100 metal + 100 gems + powerups | $9.99 |
| `pack_mega`    | Mega Pack     | 1000 coins + 500 wood + 200 metal + 200 gems + 10 of each powerup | $19.99 |

All packs are **Consumable** (can be repurchased).

**Important:** The `productId` values here must exactly match the `productId` fields in `StoreRules.packs` in `lib/domain/rules/store_rules.dart`.

---

## PART 5 — Testing Before Going Live

### Step 5.1 — Simulation Mode (No Play Store Required)

The app has a built-in simulation mode. In `lib/app_constants.dart`:

```dart
static const bool playStore = false;  // simulation mode
```

When `playStore = false`:
- Tapping buy buttons in the Gems and Packs tabs instantly grants the items.
- A dialog shows "Simulated Purchase — no real money charged".
- No Google account or Play Console needed.

Use this mode during development and testing.

### Step 5.2 — Internal Testing Track

Before publishing publicly, use Internal Testing:

1. In Play Console, go to **Testing > Internal testing**.
2. Click **"Create new release"**.
3. Upload your `app-release.aab` file.
4. Add testers by email (your own email, QA testers, etc.).
5. Testers install the app via the internal testing link.

Internal testers can make real in-app purchases without being charged (Google provides test payment methods).

### Step 5.3 — Enable Real Payments in the App

When you're ready to test real Play Store payments:

1. Set `playStore = true` in `lib/app_constants.dart`.
2. Build a new release AAB.
3. Upload to the Internal Testing track.
4. Add yourself as an internal tester.
5. Install via the testing link (not via `flutter run`).

**Note:** The `in_app_purchase` package only works in real Play Store builds, not in debug/`flutter run` sessions.

### Step 5.4 — License Testers (Free Purchases)

To test purchases without spending real money:

1. In Play Console, go to **Setup > License testing**.
2. Add your Google account email.
3. Set **License response** to **"RESPOND_NORMALLY"**.
4. License testers can make purchases that are charged but immediately refunded.

### Step 5.5 — Closed/Open Testing

After internal testing:
1. **Closed Testing (Alpha)**: Small group of real users.
2. **Open Testing (Beta)**: Anyone can join.
3. Move through these stages before production.

---

## PART 6 — Implement Purchase Verification (Server-Side, Optional but Recommended)

For production, you should verify purchases server-side to prevent fraud. The basic flow:

1. User buys a product → Play Store returns a `purchaseToken`.
2. Send `purchaseToken` + `productId` to your backend server.
3. Your server calls the Google Play Developer API to verify the purchase.
4. Only then grant the items.

This is optional for a small indie app but recommended to prevent cheating.

---

## PART 7 — Publish to Production

### Step 7.1 — Production Release

1. Go to **Testing > Production**.
2. Click **"Create new release"**.
3. Upload the `app-release.aab`.
4. Write release notes (what's new in this version).
5. Click **"Review release"**, then **"Start rollout to Production"**.

### Step 7.2 — Rollout Percentage

You can start with a partial rollout (e.g., 10% of users) to catch issues before full release:
- Start at 10% → 25% → 50% → 100% as you gain confidence.

### Step 7.3 — Review Time

Google typically reviews new apps in **1–3 days**. After approval, your app goes live on the Play Store.

---

## PART 8 — After Publishing

### Monitoring

- **Play Console Dashboard**: Daily installs, ratings, crashes.
- **Android Vitals**: ANRs (App Not Responding) and crash rates.
- **Revenue**: In **Monetize > Financial reports**.

### Updating the App

Every update requires:
1. Incrementing `versionCode` (e.g., `+2`, `+3`) in `pubspec.yaml`.
2. Building a new AAB.
3. Uploading to Play Console.
4. Creating a new release on the production track.

### Adding New Products

Add new in-app product IDs in Play Console **before** releasing the app version that references them. Products not yet in Play Console will fail to load.

---

## Quick Reference Checklist

- [ ] Pay $25 developer fee at https://play.google.com/console
- [ ] Complete developer profile
- [ ] Set unique `applicationId` in `build.gradle`
- [ ] Generate and configure signing keystore
- [ ] Run `flutter build appbundle --release`
- [ ] Create app in Play Console
- [ ] Complete store listing (screenshots, description, icon)
- [ ] Complete content rating questionnaire
- [ ] Add privacy policy URL
- [ ] Register all 11 in-app products (6 gem packs + 5 regular packs)
- [ ] Upload AAB to Internal Testing track
- [ ] Test purchases with license testers
- [ ] Set `playStore = true` in `app_constants.dart`
- [ ] Build and upload production AAB
- [ ] Roll out to production
