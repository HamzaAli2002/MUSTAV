# MUSTAV Mobile — Testing & Verification Script

Follow these in order on a **physical Android device** (same as your
streaming-app testing setup). Record your screen the whole time — you can
cut the recording into per-deliverable clips afterward.

Before starting: `flutter pub get`, then `flutter run` (not `--release`,
so you can still see logs if something breaks).

---

## Test 1 — Cart durability (spec 3.2 / evaluation #1)

1. Open the app, go to the menu, add 2–3 different burgers to the cart —
   include at least one with add-ons selected (open a product detail
   screen, tick "Extra Cheese" + "Add Bacon", set quantity to 2, add to
   cart).
2. Open the cart, confirm items/quantities/add-ons look right.
3. Go to the **recent apps switcher** and **swipe the app away** (this is
   a real kill, not just backgrounding — pressing Home alone doesn't
   count).
4. Relaunch the app from the home screen icon.
5. Open the cart again.
6. **Pass condition:** every item, quantity, and add-on is byte-identical
   to step 2. Nothing missing, nothing duplicated.

Record: steps 1–2 (cart contents), the swipe-away gesture, the relaunch,
and step 5 (cart contents again) — side by side proves nothing was lost.

---

## Test 2 — Order flow + retry (spec 3.4 / evaluation #2)

**2a — Happy path:**
1. Select a store location, add items to cart, go to Checkout.
2. Fill delivery details, pick a payment method, tap **Place Order**.
3. Confirm you land on the "ORDER PLACED!" screen with the correct total.
4. Watch the status tracker advance on its own (Received → Preparing →
   Ready/Out for Delivery → Delivered) — this happens automatically on a
   timer, no action needed.

**2b — Failure + retry (the important one):**
1. Add items to cart again, go to Checkout.
2. Because `AppConstants.simulateRandomOrderFailure` is on, roughly 1 in
   5 attempts will fail — if the first attempt succeeds, place another
   order until you hit a failure. (Or temporarily edit
   `lib/core/constants.dart` and set the failure chance to `1.0` in
   `order_repository.dart`'s `_random.nextDouble() < 0.2` line, test, then
   set it back.)
3. When it fails, confirm: the error banner shows, **the cart still has
   your items** (go check — don't just trust the screen), and a **"Order
   failed to send"** notification appears even though the app is in
   foreground.
4. Tap **Retry Order**. Confirm it resubmits the same items without you
   re-entering anything.

Record: a failed attempt, cart still intact, then a successful retry.

---

## Test 3 — Location handling (spec 3.3 / evaluation #3)

1. Fresh install (or clear app data): open the location picker, tap **Use
   my current location**. Grant the permission when prompted. Confirm it
   suggests the geographically nearest of the four cities and the map
   centers there.
2. Clear app data again (or reinstall). This time **deny** the location
   permission. Confirm: no crash, an inline message appears ("Location
   permission wasn't granted — pick your city below instead"), and the
   manual city list below still works.
3. Turn off **Location Services** entirely in Android settings, then tap
   "Use my current location" in the app. Confirm the "Location services
   are off" message appears — again, no crash, no dead end.
4. Confirm the map itself renders (OpenStreetMap tiles visible, 4 pins
   placed correctly over Lahore/Islamabad/Rawalpindi/Multan).

Record: all three permission states (granted/denied/services-off) and
the rendered map.

---

## Test 4 — Background order-status notifications (spec 3.4 / evaluation #2)

1. Place an order successfully.
2. Immediately **press Home** (background the app — don't kill it) or
   **swipe it away entirely** (kill it) — test both if you have time.
3. Wait and watch your notification tray. You should get:
   - "Order Received" — immediately
   - "Preparing your order" — ~20 seconds after placing
   - "Ready / Out for Delivery" — ~60 seconds after placing
   - "Delivered" — ~120 seconds after placing
4. Reopen the app. If you killed it, confirm it drops you back into the
   order-tracking screen showing the correct current status (not the
   menu, not a blank state).

Record: the notification tray receiving each notification while the app
is backgrounded/killed, and the reopen behavior.

---

## Test 5 — Memory profiling (spec 3.6 / evaluation #4 / deliverable #3)

This is the one deliverable that **must** be produced on your machine —
it can't be simulated.

1. Run in profile mode: `flutter run --profile`.
2. Open **Flutter DevTools** (the terminal prints a link, or open it from
   your IDE) → **Memory** tab.
3. On the device: go to the menu screen and **rapidly scroll up and down**
   through the full burger list for ~20 seconds.
4. Then repeatedly tap into a product detail screen and back out, 8–10
   times in a row.
5. Repeat the scroll for another 20–30 seconds.
6. Watch the memory timeline in DevTools: it should climb a bit initially
   (image decode buffers filling in) and then **plateau** — flatten out
   rather than climbing indefinitely.
7. **Screenshot the DevTools memory graph** at the point it plateaus.
   This screenshot + a one-paragraph note ("plateaus around X MB after
   initial scroll, remains flat under repeated navigation") is deliverable
   #3.

---

## Test 6 — Offline resilience (spec 3.5 / evaluation #5)

1. With the app open and menu already loaded once, turn on **Airplane
   Mode**.
2. Confirm: the orange offline banner appears at the top of the menu
   screen, the menu itself still shows all items (from cache, not blank),
   and you can still add items to the cart / edit quantities.
3. Go to the cart, confirm the **Checkout** button is disabled with the
   "you're offline" message.
4. Turn Airplane Mode back off. Confirm the banner disappears and the app
   doesn't glitch or lose the cart during the reconnect.

Record: the banner appearing, menu still browsable, checkout disabled,
then reconnect.

---

## Test 7 — Type safety (spec 3.7 / evaluation #6)

This one's a terminal check, not a screen recording:

```bash
dart analyze --fatal-infos
```

Run this from the project root. It should report **no errors**. If you
added an `analysis_options.yaml` with `flutter_lints`, this also catches
accidental `dynamic` usage or missing types. Screenshot the clean output
for your submission notes.

---

## What to actually submit

Per the assignment's deliverables list:
1. Source repo + README (already written).
2. A build the reviewer can install — either an APK (`flutter build apk
   --release`, output lands in
   `build/app/outputs/flutter-apk/app-release.apk`) or clear
   `flutter run` instructions.
3. Memory-profiling screenshot + note (Test 5 above).
4. Offline-caching + conflict/staleness note — already written in the
   README's section on offline strategy; you can paste it as-is or
   summarize in your own words.

The recordings from Tests 1, 2, 4, and 6 are strong evidence for the
evaluation criteria even though they're not explicitly listed as
required files — worth keeping even just as backup if a reviewer asks
"prove it."
