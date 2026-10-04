# הוצאות – Expenses App

A simple Hebrew (RTL) monthly expenses tracker, modelled on a Google Sheet:

- **חודש** – log expenses (הסבר / תאריך / סכום / סוג הוצאה). Below the list: sum per category and its percentage of the month total (`0.000%`), plus income / expenses / profit.
- **סיכום** – every month side by side: expenses, income, profit. Tap a month to set a different income for it.
- **ארכיון** – monthly PDFs saved on the phone; open them, and restore a month's data from a PDF.
- **הגדרות** – default monthly income.

## Safety & sorting
- Deleting an expense or an additional income asks for confirmation first.
- **Previous versions:** before every change the app keeps the month as it was (last 10 per month, stored inside the app). The history button on the month screen lists them; open one to view it and restore it.
- Tap the תאריך / סכום / סוג הוצאה headers of the expenses table to sort (tap again to flip). Display only; PDFs stay in date order.

## Data & PDFs
- Data is stored locally on the device (shared_preferences / browser localStorage).
- **Android:** exactly one `expenses_YYYY_MM.pdf` per month. It is rewritten automatically about 2 seconds after every change. If a month's data is removed, its PDF is deleted. There is no manual save button.
- Each PDF embeds the month's raw data, so it can be imported back.
- **Android:** PDFs are written to `Documents/expenses_app/`. This needs "All files access", which the app asks for once. If access is denied, PDFs go to the app's private folder.
- **iPhone (PWA):** open https://koren-expenses.web.app/ in Safari → Share → "Add to Home Screen". Hosted on Firebase Hosting (project `koren-expenses`). For PDFs, browsers can't write files on their own, so the share sheet opens – choose "Save to Files". At month end the app shows a reminder.

## Build
```
flutter test
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
flutter build web --release --base-href /   # build/web
firebase deploy --only hosting               # -> https://koren-expenses.web.app
```
