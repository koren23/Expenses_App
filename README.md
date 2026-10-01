# הוצאות – Expenses App

A simple Hebrew (RTL) monthly expenses tracker, modelled on a Google Sheet:

- **חודש** – log expenses (הסבר / תאריך / סכום / סוג הוצאה). Below the list: sum per category and its percentage of the month total (`0.000%`), plus income / expenses / profit.
- **סיכום** – every month side by side: expenses, income, profit. Tap a month to set a different income for it.
- **ארכיון** – monthly PDFs saved on the phone; open them, and restore a month's data from a PDF.
- **הגדרות** – default monthly income.

## Data & PDFs
- Data is stored locally on the device (shared_preferences / browser localStorage).
- The PDF button saves `expenses_YYYY_MM.pdf`; pressing it again overwrites it. When a month ends the app re-saves that month's PDF automatically on next launch.
- Each PDF embeds the month's raw data, so it can be imported back.
- **Android:** PDFs are written silently to `Android/data/com.koren23.expenses_app/files/ExpensesPDF/`.
- **iPhone (PWA):** browsers can't write files on their own, so the share sheet opens – choose "Save to Files". At month end the app shows a reminder.

## Build
```
flutter test
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
flutter build web --release   # build/web – host it (e.g. GitHub Pages) and "Add to Home Screen" on iPhone
```
