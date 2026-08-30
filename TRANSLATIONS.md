# Terminology — what changed, and what still wants a native eye

Done 2026-08-31. The in-app strings now use the term each market's brokers and fund factsheets
actually print, rather than a translation of the English.

## What was changed

| | English | Was | Now |
|---|---|---|---|
| es | Starting amount | Importe inicial | **Capital inicial** |
| es | Monthly contribution | Aportación mensual | **Aportación periódica** |
| fr | Starting amount | Montant initial | **Capital initial** |
| fr | Interest earned | Intérêts générés | **Intérêts composés** |
| de | Starting amount | Startbetrag | **Startkapital** |
| de | Capital gains tax | Kapitalertragsteuer | **Abgeltungsteuer** |
| de | Interest earned | Erwirtschaftete Erträge | **Zinseszins** |
| zh | Monthly contribution | 每月投入 | **每月定投** |
| zh | Starting amount | 初始金额 | **初始本金** |
| ja | Annual return | 年利回り | **想定利回り（年率）** |
| ja | Management fee | 年間信託報酬 | **信託報酬（年率）** |
| ar | compounding | الربح المركّب | **الفائدة المركبة** |
| he | Interest earned | רווחי השקעה | **רווחי ריבית דריבית** |

The empty-state sentence was rewritten in every language; it was the most literary string in the
app and the most obviously translated.

## Still worth a native check, and why

These are the places where the right word depends on what local brokers print, not on grammar.
A native speaker who invests can settle each one in a minute.

1. **de — `Abgeltungsteuer` vs `Kapitalertragsteuer`.** Abgeltungsteuer is the specific German flat
   tax on investment gains and is what a broker statement says. Kapitalertragsteuer is the
   withholding mechanism and is broader. If the app is aimed beyond Germany — Austria uses
   *Kapitalertragsteuer (KESt)* — the broader one may travel better.
2. **de — `Verwaltungsgebühr` vs `TER`.** Fund factsheets print *TER* or *laufende Kosten*.
   Verwaltungsgebühr is correct but reads retail-bank rather than fund.
3. **ar — regional split.** Gulf and Egyptian financial vocabulary diverge. `الفائدة المركبة` is
   safe everywhere; `رسوم الإدارة` and `ضريبة الأرباح الرأسمالية` are worth confirming against a
   Gulf brokerage.
4. **ja — `譲渡益課税` vs `キャピタルゲイン税`.** The first is the legal and broker term; the second is the
   loanword and is more recognisable to younger investors.
5. **zh — mainland vs Taiwan/HK.** The strings use simplified mainland terms: 定投, 年化收益率,
   资本利得税. Traditional-character markets say 定期定額 and 資本利得稅.
6. **es — Spain vs Latin America.** `plusvalías` is Spain's term; several Latin American markets say
   `ganancias de capital`.

## Register — decided, do not "fix" it

Hebrew mixes the imperative (`חשב`, `בדוק`) with the gerund (`שמירה`, `ייצוא`). Apple and Google's
own Hebrew style is uniformly gerund, partly so the interface never has to guess the reader's
gender.

**Edgar chose to keep `חשב` on 2026-08-31.** It is short, it is what Israeli apps commonly print on
a primary button, and it is his call. `בדוק את הנתונים` stays imperative alongside it for the same
reason — switching only one of them would be worse than either choice made consistently.

Leave both as they are. This is a decision, not an oversight.
