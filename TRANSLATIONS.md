# Translation review — queued for 2026-08-30

## The one sentence to start with

> Do the translation pass in TRANSLATIONS.md

Everything needed is below. No context from the previous session is required.

## The task

`lib/l10n/app_*.arb` — 8 locales, ~46 keys each. English and Hebrew were written carefully and
read well. The other six were written in one pass and have not been reviewed. Rewrite anything
that reads as translated rather than written.

After editing, always:

    flutter gen-l10n && flutter analyze && flutter test

Each ARB must stay valid JSON and keep every key the English file has. `yearsValue` carries ICU
plurals — Arabic needs its `few`/`many` categories, Hebrew its `=2` dual. Do not flatten those.

## Where I am least confident, in priority order

These are the specific places I hedged while writing them. Start here.

1. **`emptyBody`** — the empty-state sentence, in every language. It is the most "literary" string
   in the app and therefore the most likely to read as machine output. The Chinese
   ("复利在时间里能积累出什么") and Japanese ("複利が時間をかけて生み出すもの") versions in
   particular are vague where the English is concrete.

2. **Arabic `capitalGainsTax` and compound-interest wording.** I used `الربح المركّب` for
   compounding; `الفائدة المركبة` is the more standard financial term. Check which the Gulf and
   Egyptian markets actually use, and make `ضريبة الأرباح الرأسمالية` match local usage.

3. **Financial terms must match each market's convention, not translate literally:**
   - `managementFee` — Japanese `信託報酬` is right for a fund; German `Verwaltungsgebühr` may be
     better as `Verwaltungskosten` or `TER` depending on audience.
   - `capitalGainsTax` — German `Kapitalertragsteuer` is correct; French
     `Impôt sur les plus-values` is correct; verify the Spanish and Chinese.
   - `annualReturn` — check that each reads as "expected return", not "interest".

4. **`disclaimer`.** Quasi-legal. It must not read as advice in any language, and both app stores
   treat financial advice as a review risk. Verify each version still clearly disclaims.

5. **Register and formality.** English uses "you" informally. German currently uses `du`, French
   `vous` — that inconsistency is deliberate per language convention but worth a second opinion.
   Japanese uses polite masu form throughout; keep it.

6. **Length.** German and French strings are the longest and are the ones most likely to overflow.
   After editing, re-run the E2E screenshots and look at the results screen and the settings sheet:

       flutter drive --driver=test_driver/integration_test.dart \
         --target=integration_test/walkthrough_test.dart \
         -d "iPhone 16 Pro" --dart-define=SKIP_PRIVACY_PROMPTS=true

   Screenshots land in `screenshots/`.

## What NOT to change

- `appTitle` stays "Compound" in Latin script in every locale — it is the brand.
- Hebrew and English are fine. Only touch them if something is actually wrong.
- Do not add or remove keys. If a language genuinely needs a different phrasing structure, say so
  rather than inventing a key.

## Caveat worth telling Edgar again

I can raise these from "machine-quality" to "fluent and idiomatic". I cannot certify them the way
a native speaker in that market would — especially for the financial terms in point 3, where the
right word depends on what local brokers actually print on statements. For a finance app going to
eight markets, budget a real reviewer for at least ar, zh, ja before launch.
