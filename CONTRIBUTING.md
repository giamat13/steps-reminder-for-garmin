# Contributing to Steps Reminder Widget

יש לכם רעיון לשיפור או שמצאתם תקלה? אשמח לעזרתכם!

## How to Contribute / איך אפשר לעזור?

### 🐛 Reporting Issues / דיווח על בעיות
אם מצאתם באג או שיש לכם הצעה, פתחו **Issue** חדש במאגר.

**Please include / אנא כללו:**
- Device model (e.g., Fenix 7 Pro)
- Firmware version
- Steps to reproduce the issue
- Expected vs actual behavior
- Screenshots if relevant

### 💻 Pull Requests / שליחת שינויים
רוצים לתקן קוד או להוסיף פיצ'ר?

1. בצעו **Fork** למאגר
2. צרו Branch חדש לשינוי שלכם:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. בצעו את השינויים שלכם
4. הריצו בדיקות (אם רלוונטי)
5. Commit עם הודעה ברורה:
   ```bash
   git commit -m "Add: description of your changes"
   ```
6. Push ל-Fork שלכם:
   ```bash
   git push origin feature/your-feature-name
   ```
7. שלחו **Pull Request** עם הסבר על השינוי

### 🌍 Adding Device Support / הוספת תמיכה במכשירים
רוצים להוסיף תמיכה לשעון נוסף?

1. ערכו את `manifest.xml`
2. הוסיפו את ה-product ID:
   ```xml
   <iq:product id="your-device-id"/>
   ```
3. בדקו שהקוד עובד על המכשיר
4. שלחו PR

### 📝 Code Style Guidelines / הנחיות סגנון קוד

- השתמשו ב-4 spaces לindentation
- הוסיפו comments בעברית או אנגלית
- שמות משתנים באנגלית, descriptive
- Function names: camelCase
- Class names: PascalCase

### 🧪 Testing / בדיקות

לפני שליחת PR, אנא:
1. בדקו על סימולטור
2. אם אפשרי, בדקו על מכשיר פיזי
3. ודאו שההגדרות עובדות
4. בדקו את שתי השפות (עברית ואנגלית)

### 🗣️ Language / שפה

- Code comments: English or Hebrew
- Commit messages: English
- Issue discussions: English or Hebrew
- PR descriptions: English with Hebrew summary if needed

### 📦 What We're Looking For / מה אנחנו מחפשים

**Feature requests we'd love:**
- Support for more Garmin devices
- Additional notification options
- More flexible scheduling options
- UI improvements
- Battery optimization

**תוספות שנשמח להן:**
- תמיכה במכשירי Garmin נוספים
- אפשרויות התראה נוספות
- גמישות בלוח זמנים
- שיפורי UI
- אופטימיזציה של צריכת סוללה

### ⚖️ License / רישיון

בשליחת תרומה, אתם מסכימים שהקוד שלכם יהיה תחת רישיון CC BY-NC 4.0.

### 🙏 Thank You / תודה

כל תרומה, קטנה או גדולה, מוערכת מאוד!  
Every contribution, small or large, is greatly appreciated!

---

**Questions?** Open an issue or discussion!  
**שאלות?** פתחו issue או discussion!
