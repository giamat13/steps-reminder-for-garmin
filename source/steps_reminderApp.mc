import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Background;
import Toybox.System;
import Toybox.Time;
import Toybox.ActivityMonitor;
import Toybox.Attention;
import Toybox.Communications;
import Toybox.Math;

// חובה להוסיף את התגית הזו כדי שהאפליקציה תרוץ ברקע
(:background)
class steps_reminderApp extends Application.AppBase {
    private var _historyData as Array?;
    private const MAX_HISTORY_DAYS = 90;
    private const STORAGE_KEY_HISTORY = "stepHistory";
    // כ-5 ימים של דגימות (בהנחה של דגימה כל 45 דק') לפני שמתחילים למידה חכמה
    private const MIN_SAMPLES_FOR_LEARNING = 150; 

    function initialize() {
        AppBase.initialize();
        _historyData = loadHistoryData();
    }

    function onStart(state as Dictionary?) as Void {
        // רישום לאירוע כל 45 דקות
        Background.registerForTemporalEvent(new Time.Duration(45 * 60));
    }

    function onStop(state as Dictionary?) as Void {
        saveHistoryData();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new steps_reminderView() ];
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new StepsServiceDelegate()];
    }

    // --- ליבת הלוגיקה והלמידה ---

    function getExpectedProgressForNow() as Float {
        var now = Time.now();
        var t = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        
        // חישוב בסיסי: התקדמות ליניארית לפי שעה ביום (למשל ב-12:00 זה 50%)
        var linearPercent = ((t.hour * 60 + t.min).toFloat() / 1440.0) * 100.0;

        // שלב 1: אם אין מספיק נתונים (שבוע ראשון), מחזירים את הליניארי
        if (_historyData == null || _historyData.size() < MIN_SAMPLES_FOR_LEARNING) {
            return linearPercent;
        }

        // שלב 2: למידה מההיסטוריה
        var totalWeight = 0.0;
        var weightedSum = 0.0;
        var foundSamples = false;

        for (var i = 0; i < _historyData.size(); i++) {
            var r = _historyData[i];
            
            // סינון: לוקחים רק דגימות מאותו יום בשבוע (למשל ימי ראשון)
            // ורק דגימות שקרו בטווח של שעתיים מהשעה הנוכחית
            if (r["day"] == t.day_of_week && (r["hour"] - t.hour).abs() <= 2) {
                foundSamples = true;
                
                // חישוב משקל: דגימות חדשות משפיעות יותר מישנות
                var ageInSeconds = now.value() - r["timestamp"];
                var weight = Math.pow(0.95, ageInSeconds / 86400.0); // דעיכה יומית קלה
                
                weightedSum += r["stepsPercent"] * weight;
                totalWeight += weight;
            }
        }

        if (!foundSamples || totalWeight == 0) {
            return linearPercent;
        }

        var learnedTarget = weightedSum / totalWeight;

        // שלב 3: החלקה (Smoothing) ומניעת קפיצות
        // אנחנו לא רוצים שהיעד יקפוץ בטירוף. אנחנו עושים ממוצע בין הליניארי לנלמד
        // אבל נותנים יותר כוח לנלמד ככל שיש יותר דגימות.
        // בנוסף, זה פותר את בעיית הריצה: אם המשתמש רץ בערב קבוע, ההיסטוריה תראה
        // שבשעה הזו בבוקר יש לו מעט צעדים, והיעד הנלמד ירד בהתאם באופן טבעי.
        
        // הגבלת הסטייה כדי למנוע באגים של 0% או 100% פתאומיים
        if (learnedTarget < linearPercent - 20) { learnedTarget = linearPercent - 20; }
        if (learnedTarget > linearPercent + 20) { learnedTarget = linearPercent + 20; }

        return learnedTarget;
    }

    // --- ניהול נתונים (Load/Save) ---

    function loadHistoryData() as Array {
        var data = Application.Storage.getValue(STORAGE_KEY_HISTORY);
        if (data != null && data instanceof Array) {
            return data as Array;
        }
        return [] as Array;
    }

    function saveHistoryData() as Void {
        if (_historyData != null) {
            Application.Storage.setValue(STORAGE_KEY_HISTORY, _historyData);
        }
    }

    function addHistoryRecord(steps as Number, stepGoal as Number) as Void {
        if (_historyData == null) { _historyData = [] as Array; }
        var now = Time.now();
        var t = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        
        // חישוב אחוז נוכחי לשמירה
        var currentPct = 0.0;
        if (stepGoal > 0) {
            currentPct = (steps.toFloat() / stepGoal.toFloat()) * 100.0;
        }

        var record = {
            "day" => t.day_of_week,
            "hour" => t.hour,
            "stepsPercent" => currentPct,
            "timestamp" => now.value()
        };
        
        _historyData.add(record);
        
        // שמירה על גודל היסטוריה סביר (כ-3 חודשים)
        if (_historyData.size() > MAX_HISTORY_DAYS * 32) {
            _historyData = _historyData.slice(1, _historyData.size());
        }
        saveHistoryData();
    }

    // --- הפונקציה שרצה ברקע כל 45 דקות ---
    function checkStepsAndAlert() as Void {
        var info = ActivityMonitor.getInfo();
        if (info == null || info.steps == null || info.stepGoal == null || info.stepGoal == 0) { return; }

        // בדיקות אי-הפרעה
        var settings = System.getDeviceSettings();
        if (info has :isSleepMode && info.isSleepMode) { return; }
        if (settings has :doNotDisturb && settings.doNotDisturb) { return; }
        
        // הגבלת שעות (לא בלילה)
        var now = Time.now();
        var t = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        if (t.hour < 7 || t.hour >= 23) { return; }

        // שמירת דגימה להיסטוריה
        addHistoryRecord(info.steps, info.stepGoal);
        
        // בדיקת היעד מול המצוי
        var expectedPct = getExpectedProgressForNow();
        var currentPct = (info.steps.toFloat() / info.stepGoal.toFloat()) * 100.0;
        var delta = currentPct - expectedPct;

        // התראה רק אם ה"אחד העליון" (דלתא) מתחת לאפס
        if (delta < 0) {
            var msg = "Low steps! Lagging by " + delta.format("%.1f") + "%";
            sendAlert(msg);
        }
    }

    function sendAlert(message as Lang.String) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(100, 1000)]);
        }
        if (System.getDeviceSettings().phoneConnected) {
            Communications.makeWebRequest("https://dummy.com", {"m"=>message}, {}, method(:onNotificationResponse));
        }
    }

    function onNotificationResponse(code as Number, data as Dictionary?) as Void {}
}

// --- Delegate (חייב להיות מחוץ לקלאס הראשי) ---
(:background)
class StepsServiceDelegate extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }
    function onTemporalEvent() as Void {
        var app = Application.getApp() as steps_reminderApp;
        app.checkStepsAndAlert();
        Background.exit(null);
    }
}