import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Background;
import Toybox.System;
import Toybox.Time;
import Toybox.ActivityMonitor;
import Toybox.Attention;
import Toybox.Communications;

class steps_reminderApp extends Application.AppBase {
    private var _historyData as Array?;
    private const MAX_HISTORY_DAYS = 90; // שמירת 90 ימים אחורה
    private const STORAGE_KEY_HISTORY = "stepHistory";

    function initialize() {
        AppBase.initialize();
        _historyData = loadHistoryData();
    }

    function onStart(state as Dictionary?) as Void {
        Background.registerForTemporalEvent(new Time.Duration(20 * 60)); // בדיקה כל 20 דקות
    }

    function onStop(state as Dictionary?) as Void {
        saveHistoryData();
        Background.deleteTemporalEvent();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new steps_reminderView() ];
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new StepsServiceDelegate()];
    }

    // טעינת היסטוריה מהזיכרון
    function loadHistoryData() as Array {
        var storage = Application.Storage;
        var data = storage.getValue(STORAGE_KEY_HISTORY);
        
        if (data != null && data instanceof Array) {
            return data as Array;
        }
        
        return [] as Array;
    }

    // שמירת היסטוריה לזיכרון
    function saveHistoryData() as Void {
        var storage = Application.Storage;
        if (_historyData != null) {
            storage.setValue(STORAGE_KEY_HISTORY, _historyData);
        }
    }

    // הוספת נתון היסטורי
    function addHistoryRecord(steps as Number, stepGoal as Number, timePercent as Float) as Void {
        if (_historyData == null) {
            _historyData = [] as Array;
        }
        
        var now = Time.now();
        var timeInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        
        var record = {
            "day" => timeInfo.day_of_week, // 1=Sunday, 7=Saturday
            "hour" => timeInfo.hour,
            "steps" => steps,
            "stepGoal" => stepGoal,
            "stepsPercent" => (steps.toFloat() / stepGoal.toFloat()) * 100,
            "timePercent" => timePercent,
            "timestamp" => now.value()
        };
        
        _historyData.add(record);
        
        // שמירה על מקסימום ימים
        if (_historyData.size() > MAX_HISTORY_DAYS * 72) { // 72 = 24 hours * 3 samples per hour
            _historyData = _historyData.slice(_historyData.size() - (MAX_HISTORY_DAYS * 72), _historyData.size());
        }
        
        saveHistoryData();
    }

    // חישוב התקדמות צפויה לפי למידה מהיסטוריה
    function getExpectedProgressForNow() as Float {
        if (_historyData == null || _historyData.size() < 10) {
            // אין מספיק נתונים - נשתמש בלוגיקה הליניארית הבסיסית
            var now = Time.now();
            var timeInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
            var currentMinutes = timeInfo.hour * 60 + timeInfo.min;
            return (currentMinutes.toFloat() / 1440.0) * 100.0; // יחס ליניארי
        }
        
        var now = Time.now();
        var timeInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var currentDay = timeInfo.day_of_week;
        var currentHour = timeInfo.hour;
        
        // מציאת רשומות דומות מהעבר (אותו יום בשבוע, אותה שעה בערך)
        var relevantRecords = [] as Array;
        
        for (var i = 0; i < _historyData.size(); i++) {
            var record = _historyData[i];
            
            // אותו יום בשבוע ואותה שעה (±2 שעות)
            if (record["day"] == currentDay && 
                (record["hour"] - currentHour).abs() <= 2) {
                relevantRecords.add(record);
            }
        }
        
        if (relevantRecords.size() == 0) {
            // אין נתונים לרלוונטיים - נשתמש בממוצע כללי
            return calculateOverallAverage();
        }
        
        // חישוב ממוצע משוקלל (נתונים חדשים יותר מקבלים משקל גבוה יותר)
        var totalWeight = 0.0;
        var weightedSum = 0.0;
        
        for (var i = 0; i < relevantRecords.size(); i++) {
            var record = relevantRecords[i];
            var age = now.value() - record["timestamp"];
            var daysSinceRecord = age / (24 * 60 * 60);
            
            // משקל יורד אקספוננציאלית עם הזמן
            var weight = Math.pow(0.95, daysSinceRecord);
            
            weightedSum += record["stepsPercent"] * weight;
            totalWeight += weight;
        }
        
        if (totalWeight > 0) {
            return weightedSum / totalWeight;
        }
        
        return calculateOverallAverage();
    }

    // חישוב ממוצע כללי
    function calculateOverallAverage() as Float {
        if (_historyData == null || _historyData.size() == 0) {
            var now = Time.now();
            var timeInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
            var currentMinutes = timeInfo.hour * 60 + timeInfo.min;
            return (currentMinutes.toFloat() / 1440.0) * 100.0;
        }
        
        var sum = 0.0;
        for (var i = 0; i < _historyData.size(); i++) {
            sum += _historyData[i]["stepsPercent"];
        }
        
        return sum / _historyData.size();
    }

    function checkStepsAndAlert() as Void {
        var activityInfo = ActivityMonitor.getInfo();
        
        if (activityInfo == null) {
            return;
        }

        var currentSteps = activityInfo.steps;
        var stepGoal = activityInfo.stepGoal;
        
        if (currentSteps == null || stepGoal == null || stepGoal == 0) {
            return;
        }

        var now = Time.now();
        var timeInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var currentMinutes = timeInfo.hour * 60 + timeInfo.min;
        var totalMinutesInDay = 24 * 60;
        var dayProgress = currentMinutes.toFloat() / totalMinutesInDay.toFloat();
        var timePercent = dayProgress * 100;
        var stepsPercent = (currentSteps.toFloat() / stepGoal.toFloat()) * 100;

        // הוספת נתון היסטורי
        addHistoryRecord(currentSteps, stepGoal, timePercent);

        // קבלת התקדמות צפויה לפי למידה
        var expectedProgress = getExpectedProgressForNow();

        var props = Application.Properties;
        var usePercent = props.getValue("usePercent");
        var timeThreshold = props.getValue("timeThreshold");
        var stepsThreshold = props.getValue("stepsThreshold");

        if (usePercent == null) { usePercent = true; }
        if (timeThreshold == null) { timeThreshold = 50; }
        if (stepsThreshold == null) { stepsThreshold = 50; }

        var shouldAlert = false;
        var alertMessage = "";

        if (usePercent) {
            // מצב אחוזים - השוואה יחסית עם למידה
            // נשווה את ההתקדמות בפועל להתקדמות הצפויה
            if (stepsPercent < expectedProgress - 5) { // מרווח של 5% למניעת התראות מיותרות
                shouldAlert = true;
                alertMessage = Lang.format("$1$% steps vs expected $2$% at this time", 
                    [stepsPercent.format("%.0f"), expectedProgress.format("%.0f")]);
            }
        } else {
            // מצב מוחלט
            if (currentMinutes >= timeThreshold && currentSteps < stepsThreshold) {
                shouldAlert = true;
                var hoursElapsed = (currentMinutes / 60).format("%d");
                var minutesElapsed = (currentMinutes % 60).format("%02d");
                alertMessage = Lang.format("$1$:$2$ - Only $3$ steps (goal: $4$)", 
                    [hoursElapsed, minutesElapsed, currentSteps, stepsThreshold]);
            }
        }

        if (shouldAlert) {
            sendAlert(alertMessage);
        }
    }

    function sendAlert(message as String) as Void {
        // רטט ב-Watch
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_ALERT_HI);
        }
        
        if (Attention has :vibrate) {
            var vibeProfile = [
                new Attention.VibeProfile(50, 200),
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(50, 200)
            ];
            Attention.vibrate(vibeProfile);
        }

        // שליחה לטלפון דרך Garmin Connect
        if (Communications has :makeWebRequest) {
            try {
                var params = {
                    "title" => "Steps Reminder",
                    "message" => message
                };
                
                // Garmin Connect תומך בהתראות דרך phoneMessage
                if (System.getDeviceSettings() has :phoneConnected && 
                    System.getDeviceSettings().phoneConnected) {
                    
                    // שימוש ב-makeWebRequest לשליחת התראה
                    Communications.makeWebRequest(
                        "https://services.garmin.com/appstorecontent/connect-iq/notification",
                        params,
                        {
                            :method => Communications.HTTP_REQUEST_METHOD_POST,
                            :headers => {
                                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                            }
                        },
                        method(:onNotificationResponse)
                    );
                }
            } catch (ex) {
                // אם יש שגיאה בשליחת ההתראה, נמשיך בלי לקרוס
                System.println("Failed to send notification: " + ex.getErrorMessage());
            }
        }
    }

    function onNotificationResponse(responseCode as Number, data as Dictionary?) as Void {
        // Callback ריק - אנחנו לא צריכים לעשות כלום עם התשובה
    }

    // פונקציה לניקוי היסטוריה ישנה (אופציונלי)
    function cleanOldHistory() as Void {
        if (_historyData == null || _historyData.size() == 0) {
            return;
        }
        
        var now = Time.now();
        var cutoffTime = now.value() - (MAX_HISTORY_DAYS * 24 * 60 * 60);
        
        var newHistory = [] as Array;
        for (var i = 0; i < _historyData.size(); i++) {
            if (_historyData[i]["timestamp"] >= cutoffTime) {
                newHistory.add(_historyData[i]);
            }
        }
        
        _historyData = newHistory;
        saveHistoryData();
    }
}

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

function getApp() as steps_reminderApp {
    return Application.getApp() as steps_reminderApp;
}
