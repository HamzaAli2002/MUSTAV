# MUSTAV Mobile — Khizex Week 2 Build

A native Flutter app for MUSTAV's smashed-burger ordering experience
(mustav.vercel.app), built for the Khizex Mobile Engineering Internship
Week 2 assignment. Real menu data (names, prices in PKR, prep times, spice
levels, bun/patty, calories, protein) was pulled directly from the live
site's `/menu` page and seeded into the app.

**Visual fidelity note:** the theme, fonts, menu layout, checkout flow,
loading animation, and nav overlay were rebuilt to match a screen
recording of the live site frame-by-frame (colors pixel-sampled directly
from captured frames) — see section 8 below for the exact palette and
per-screen mapping. The site is a warm cream/maroon/red/yellow design,
**not** dark — if you're comparing against an earlier version of this
README/app, that was wrong and has been corrected.

## 1. Setup

This repo ships only the `lib/` source + `pubspec.yaml` — you need to
generate the native `android/`/`ios/` scaffolding locally (it can't be
committed generically since it depends on your Flutter/Android SDK
versions):

```bash
# From an empty folder:
flutter create --org com.khizex --project-name mustav_mobile .
# Then copy this repo's lib/ and pubspec.yaml over the generated ones.
flutter pub get
```

### Android manifest additions (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

No Google Maps API key needed — the map view uses **OpenStreetMap** tiles via
`flutter_map`, which is free with no API key and no billing account (see
section 9 below for why).

### iOS `Info.plist` additions

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>MUSTAV uses your location to suggest the nearest store.</string>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

Run on a device: `flutter run` (verified target: physical Android device,
same as the streaming-app build).

## 2. Architecture

```
lib/
  models/        Strictly-typed data: Burger, AddOn, CartItem, Order,
                  StoreLocation, and shared enums (SpiceLevel, BunType,
                  PattyType, OrderStatus, CityName). No dynamic, no raw maps
                  passed between layers — everything crosses layer
                  boundaries as a typed object.
  data/
    db/           AppDatabase — single sqflite instance, schema for menu
                  cache, locations, cart, and order history.
    repositories/ MenuRepository, CartRepository, LocationRepository,
                  OrderRepository — the only things that touch AppDatabase.
  services/       ConnectivityService, GeolocationService,
                  NotificationService — thin wrappers around
                  connectivity_plus / geolocator / flutter_local_notifications.
  providers/      Riverpod state — cart, menu (+ filters), location
                  resolution, connectivity, checkout/order lifecycle.
  screens/        Menu (catalog grid), product detail, cart, location
                  picker, checkout, order tracking.
```

State management: **Riverpod**, per your existing stack. Persistence:
**sqflite**, per the spec's "SQLite/Realm/WatermelonDB" options.

## 3. Cart persistence (spec 3.2)

`CartNotifier` (`providers/cart_provider.dart`) is an `AsyncNotifier` whose
`build()` rehydrates from `AppDatabase` on every app start. Every mutation
(`addItem`, `updateQuantity`, `removeItem`, `clear`) writes to SQLite
**immediately**, in the same call — not on `didChangeAppLifecycleState` or
app close. Force-killing the app mid-session and relaunching replays
exactly what's in the `cart_items` / `cart_item_addons` tables.

**To verify:** add a few items with add-ons, swipe the app away from the
recent-apps switcher (not just background — kill it), relaunch, open the
cart. Items, quantities, and add-ons should be identical.

## 4. Order status notifications (spec 3.4)

`NotificationService.scheduleOrderTimeline()` schedules **all four**
status notifications (Received → Preparing → Ready/Out for Delivery →
Delivered) at order-placement time using `zonedSchedule` with
`AndroidScheduleMode.exactAllowWhileIdle`. Because they're OS-scheduled up
front rather than fired by a live Dart timer, they still arrive if the app
is backgrounded or fully killed afterward. The in-app `OrderTrackingScreen`
mirrors the same timeline locally so the UI updates live while the app is
open, and `latestOrderProvider` + `resumeOrder()` re-attach to an in-flight
order if the app was killed and reopened before delivery.

A failed submission (`OrderRepository.submit` simulates a ~20% random drop
via `AppConstants.simulateRandomOrderFailure`) never touches the cart —
`CheckoutNotifier` only calls `cart.clear()` **after** a confirmed success.
On failure the same draft order is kept in state so "Retry" resubmits the
identical items with no re-entry.

## 5. Offline caching strategy (spec 3.5, deliverable #4)

There is no public MUSTAV backend, so "network fetch" is simulated per the
assignment's allowance, but the caching/fallback logic is real:

- **`MenuRepository.getMenu()`** is cache-first: it always reads
  `menu_items` from SQLite first. If online, it attempts a refresh and
  overwrites the cache (`ConflictAlgorithm.replace`) on success. If
  offline, or the refresh throws, it serves whatever's cached — and only
  falls back to the bundled `MenuSeed` constant if the cache is *also*
  empty (true first-run-offline case), so the screen is never blank.
- **Conflict/staleness handling on reconnect:** cache rows are timestamped
  (`cachedAt`). A reconnect simply re-runs `getMenu(isOnline: true)`,
  which overwrites stale rows in place — no merge conflicts are possible
  because the client never has divergent local edits to menu data (prices
  aren't user-editable). Cart data is untouched by a menu refresh; cart
  lines reference `burgerId`, not a denormalized price snapshot, so a
  price change on reconnect is reflected the next time the cart re-reads
  the (now up to date) burger from the cache. If a cart line's `burgerId`
  is no longer present in a refreshed menu, `readCart()` skips it
  defensively rather than crashing.
- **`ConnectivityService`** drives `isOnlineProvider`, which the UI uses
  to (a) show the offline banner, and (b) disable "Proceed to Checkout" /
  "Place Order" while offline — menu browsing and cart editing stay fully
  usable from cache.

## 6. Memory discipline (spec 3.6, deliverable #3)

- The menu catalog uses `GridView.builder`, which virtualizes automatically
  — off-screen cards are never built or retained.
- Images go through `CachedNetworkImage` with `memCacheWidth` set
  (480px for grid thumbnails, 900px for the detail hero image) so the
  decoder never holds a full-resolution bitmap behind a small card.
- **To produce the profiler note:** run the app via `flutter run --profile`,
  open Flutter DevTools' Memory tab, rapidly scroll the menu grid and
  navigate in/out of 5–10 product detail screens for ~60 seconds, and
  screenshot the memory timeline once it plateaus. This step needs a real
  device/emulator and can't be executed in this environment — do this on
  your machine before submitting, then attach the screenshot per the
  assignment's deliverable #3.

## 7. Strict typing (spec 3.7)

- No `dynamic` anywhere in `lib/`. All enums (`SpiceLevel`, `BunType`,
  `PattyType`, `OrderStatus`, `CityName`) are proper Dart enums with
  `fromDb`/`.name` round-trips, not raw strings passed around.
- `Burger`, `AddOn`, `CartItem`, `Order`, `StoreLocation` are all
  `Equatable` classes with typed fields — never `Map<String, dynamic>`
  crossing a repository/provider boundary.
- Recommended: enable `analysis_options.yaml` with
  `include: package:flutter_lints/flutter.yaml` and run
  `dart analyze --fatal-infos` before submitting.

## 8. Full site replication — landing page + animations

Since you asked for the complete site experience (not just the ordering
flow), I pulled the actual homepage content from `mustav.vercel.app` and
rebuilt every section natively:

| Website section | Flutter screen/widget |
|---|---|
| Nav (Home/About/Spices/Locations/Contact) | `HomeScreen`'s `Drawer` (`_NavDrawer`) |
| Hero ("SMASHED FRESH / BOLD FLAVOR", hero image, "Est. 2024") | `_HeroSection` in `home_screen.dart` |
| "SMASHED • FRESH • BOLD • CRAVE •" scrolling banner | `widgets/marquee_ticker.dart` — real infinite auto-scroll |
| "TOP CLASSIC / juicy cheesy fully Loaded" | `_TopClassicSection` |
| About image trio (chef/cheese/restaurant) | `_AboutCarousel` — swipeable `PageView` |
| "food that feels good" (flame/muscle/sparkle cards) | `_ExperienceSection` / `_FeatureCard` |
| Ingredients strip | `_IngredientsRow` |
| Locations grid (Lahore/Islamabad/Rawalpindi/Multan) | `_LocationsSection` — tapping a card sets that store as selected and opens the menu, same as the real `LocationPickerScreen` flow |
| "A story in every bite" ingredient cards | `_StoryRow` |
| Second marquee "MUSTAV • BURGERS •" | `MarqueeTicker` again |
| "feel the Change" CTA | `_FeelItSection` |
| Footer (logo, nav, locations, owner, copyright) | `_Footer` |
| "Our Spices" page | `screens/spices/spices_screen.dart` — groups the real menu by spice level |
| "Contact" page | `screens/contact/contact_screen.dart` |
| Yellow burger-building loading screen (between page navigations) | `widgets/mustav_loader.dart` — custom-painted layered burger + cycling captions ("Firing up the grill...", "Adding fresh toppings...", "Ready to serve..."), shown on app startup |
| Hamburger nav overlay (red full-screen, HOME/ABOUT/OUR SPICES/LOCATIONS/CONTACT) | `_NavDrawer` in `home_screen.dart` — red background, white bold links, "Est. 2024 — Pakistan" badge, X close |
| Checkout: Order Summary / Delivery Details / Payment Method (EasyPaisa, JazzCash, Card) | `checkout_screen.dart` — delivery fee corrected to **Rs. 50** (was wrongly Rs. 150 in an earlier version); wallet options reveal an account-number field |
| "ORDER PLACED!" confirmation | `order_tracking_screen.dart` — green checkmark card, Total, "ORDER MORE" button, with the required Received→Preparing→Ready→Delivered tracker underneath |
| "✓ Added to Cart" toast | Restyled `SnackBar` in `menu_screen.dart` with a checkmark icon, accent background |
| Empty cart illustration + "Hungry? Add items…" | `cart_screen.dart` now loads the site's actual empty-cart image |

**Animations, and how they're implemented (no extra packages beyond
`pubspec.yaml`):**
- **Marquee ticker** — `MarqueeTicker` runs a repeating `AnimationController`
  driving `Transform.translate`, with the text tripled so the viewport is
  always fully covered — a seamless infinite scroll, same as the site's
  ticker bands.
- **Scroll-reveal (fade + slide up)** — `widgets/scroll_reveal.dart`. Two
  variants: `ScrollReveal` (animates once on mount, used for the first
  above-the-fold sections) and `VisibleOnceReveal` (checks the section's
  position via `RenderBox.localToGlobal` on every scroll notification and
  triggers the same fade/slide the first time it enters the viewport —
  used for every section below the fold, so it actually reveals as you
  scroll rather than all at once).
- **Hero image parallax-style depth** — a gradient scrim over the hero
  image plus content anchored to the bottom, matching the site's dark
  vignette treatment under the headline.

`app.dart`'s startup gate now opens on `HomeScreen` (this landing
experience) instead of jumping straight to the menu — exactly like the
real site, where you land on the homepage and tap "Order Now" to reach
the menu.

## 9. Why OpenStreetMap instead of Google Maps

Google Maps SDK is free up to a generous monthly quota, but Google still
requires a billing account (card on file) to issue the API key at all.
To avoid that entirely, the location picker uses `flutter_map` rendering
**OpenStreetMap** tiles — genuinely free, no API key, no card, no signup.
This satisfies spec 3.3's "native map view (MapKit/Google Maps SDK/**or
equivalent**)" requirement. If you'd rather use Google Maps later (e.g.
for Advanced Markers or Street View), swap `flutter_map`/`latlong2` back
for `google_maps_flutter` in `pubspec.yaml` and follow Google's standard
API-key setup — the rest of the app (location provider, nearest-store
logic, persistence) is unaffected either way.

## 10. Setting the app icon and app name

By default a fresh `flutter create` gives you the generic Flutter logo and
the label "mustav_mobile". To brand it:

**App name (label shown under the icon):**
- Android: `android/app/src/main/AndroidManifest.xml` → change
  `android:label="mustav_mobile"` to `android:label="MUSTAV"` on the
  `<application>` tag.
- iOS: `ios/Runner/Info.plist` → change the `CFBundleDisplayName` value to
  `MUSTAV`.

**App icon:**
1. Add your logo image (a 1024×1024 PNG works best) to
   `assets/icon/icon.png` in the project.
2. Add to `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.13.1

   flutter_icons:
     android: true
     ios: true
     image_path: "assets/icon/icon.png"
   ```
3. Run:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```
   This regenerates every launcher icon size for both platforms
   automatically.
4. `flutter clean && flutter run` to see the new icon/name on the device.

To remove the debug banner in the corner (if you ever build in a way that
shows it) — it's already off:
`MaterialApp(debugShowCheckedModeBanner: false, ...)` in `lib/app.dart`.

## 11. Bug fixes from device testing (this round)

A round of real-device testing surfaced several issues — fixed as follows:

- **Notifications only firing once ("Order Received" but nothing after)**
  — root cause: `timezone` package defaulted to UTC instead of the
  device's real timezone, so every scheduled notification's fire-time was
  computed wrong. Fixed by adding `flutter_timezone` and calling
  `tz.setLocalLocation()` with the device's actual IANA timezone in
  `NotificationService.init()`.
- **"Place Order" stuck on an infinite loading spinner** — same root
  cause: when the (broken) notification scheduling threw an exception, it
  was uncaught and the checkout state never resolved. Fixed by wrapping
  notification calls in `try/catch` and adding a catch-all around the
  whole submission flow, so the UI always resolves to success or failure.
- **Delivery fee was a flat Rs. 50 regardless of distance** — now computed
  from the real GPS distance to the selected store: a Rs. 50 base fee
  plus Rs. 8/km, capped at Rs. 300 (`computeDeliveryFeeRs()` in
  `lib/models/order.dart`). Manual city picks (no GPS reading) fall back
  to the base fee since no distance is known.
- **Large blank sections on the home screen (about carousel, ingredients,
  locations, hero image)** — these were pointed at made-up
  `mustav.vercel.app/images/...` URLs that don't actually exist on the
  live site (they were never scraped, just guessed placeholders). Replaced
  with real, working Unsplash photo URLs so every section actually
  renders. Swap these for your own photography whenever you have it —
  search each `imageUrl:` in `lib/models/burger.dart`,
  `lib/models/store_location.dart`, and `lib/screens/home/home_screen.dart`.
- **Footer nav links / location links were plain, non-tappable text** —
  wrapped every footer entry in `InkWell` with real navigation, matching
  the header nav's behavior.
- **No way back to Home from Menu / Order Tracking screens** — added a
  home icon to both app bars, and made the "MUSTAV" wordmark itself
  tappable (matches the real site's logo-returns-home behavior). "Order
  More" on the confirmation screen now returns to Home instead of Menu.
- **Cart/location icons missing from the Home screen's app bar** — added,
  matching the Menu screen's app bar.
- **GPS "use current location" not resolving** — two things fixed: (1)
  `Geolocator.getCurrentPosition` timeout increased from 8s to 15s with a
  `getLastKnownPosition()` fallback if a fresh fix fails; (2) **you must
  add the location permissions to `AndroidManifest.xml`** (see section 1)
  — without them, Android denies the request before the app even gets a
  chance to prompt, and there's no code-side fix for a missing manifest
  entry. Double-check `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`
  are actually in your manifest and that Location is turned on for the
  Moto G in Android Settings.

## 12. What's simulated vs. real

| Feature | Status |
|---|---|
| Menu data (names/prices/macros) | Real — scraped from mustav.vercel.app |
| Store coordinates | Real approximate city-center lat/lng for Lahore/Islamabad/Rawalpindi/Multan |
| Nearest-store matching + delivery fee | Real haversine distance calculation against device GPS, drives both nearest-store suggestion and the fee |
| Order backend | Simulated (spec explicitly allows this) — local DB + timed status transitions |
| OS notifications | Real — `flutter_local_notifications`, fires even when backgrounded/killed |
| Offline detection | Real — `connectivity_plus` |
| Add-ons | Modeled — MUSTAV's site doesn't expose these, so they're typed synthetic data per spec 3.1 |
| Photography | Placeholder — real working stock photos (Unsplash) standing in for MUSTAV's actual photography; swap when you have real assets |


| Feature | Status |
|---|---|
| Menu data (names/prices/macros) | Real — scraped from mustav.vercel.app |
| Store coordinates | Real approximate city-center lat/lng for Lahore/Islamabad/Rawalpindi/Multan |
| Nearest-store matching | Real haversine calculation against device GPS |
| Order backend | Simulated (spec explicitly allows this) — local DB + timed status transitions |
| OS notifications | Real — `flutter_local_notifications`, fires even when backgrounded/killed |
| Offline detection | Real — `connectivity_plus` |
| Add-ons | Modeled — MUSTAV's site doesn't expose these, so they're typed synthetic data per spec 3.1 |
