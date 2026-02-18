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

(:background)
class steps_reminderApp extends Application.AppBase {
    var _historyData as Array<Array>?;
    private const STORAGE_KEY_HISTORY = "stepHistory";
    private const MIN_SAMPLES_FOR_LEARNING = 150;
    private const MAX_STORAGE_RECORDS = 600;

    enum { IDX_DAY = 0, IDX_HOUR = 1, IDX_PCT = 2, IDX_TS = 3 }

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var data = Application.Storage.getValue(STORAGE_KEY_HISTORY);
        
        // בדיקה אם נדרשת הגירה (אם הרשומה הראשונה היא Dictionary)
        if (data instanceof Array && data.size() > 0 && data[0] instanceof Dictionary) {
            return [ new MigrationView(data), new MigrationDelegate() ];
        }
        
        // אם אין צורך בהגירה, טען נתונים כרגיל
        _historyData = (data instanceof Array) ? data : [] as Array<Array>;
        return [ new steps_reminderView() ];
    }

    // פונקציה שנקראת בסיום ההגירה מה-MigrationView
    function finishMigration(migratedData as Array<Array>) as Void {
        _historyData = migratedData;
        saveHistoryData();
        WatchUi.switchToView(new steps_reminderView(), null, WatchUi.SLIDE_IMMEDIATE);
    }

    function onStart(state as Dictionary?) as Void {
        Background.registerForTemporalEvent(new Time.Duration(45 * 60));
    }

    function onStop(state as Dictionary?) as Void {
        saveHistoryData();
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new StepsServiceDelegate()];
    }

    function saveHistoryData() as Void {
        if (_historyData != null) {
            Application.Storage.setValue(STORAGE_KEY_HISTORY, _historyData);
        }
    }

    function getExpectedProgressForNow() as Float {
        var now = Time.now();
        var t = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        
        var startHour = 7, endHour = 23;
        var totalActiveMinutes = (endHour - startHour) * 60.0;
        var minutesSinceStart = (t.hour - startHour) * 60.0 + t.min;
        
        var linearPercent = (minutesSinceStart / totalActiveMinutes) * 100.0;
        linearPercent = (linearPercent < 0) ? 0.0 : (linearPercent > 100 ? 100.0 : linearPercent);

        if (_historyData == null || _historyData.size() < MIN_SAMPLES_FOR_LEARNING) {
            return linearPercent;
        }

        var totalWeight = 0.0, weightedSum = 0.0;
        var foundSamples = false;

        for (var i = 0; i < _historyData.size(); i++) {
            var r = _historyData[i];
            if (r[IDX_DAY] == t.day_of_week && (r[IDX_HOUR] - t.hour).abs() <= 2) {
                foundSamples = true;
                var ageInSeconds = now.value() - r[IDX_TS];
                var weight = Math.pow(0.95, ageInSeconds / 86400.0);
                weightedSum += r[IDX_PCT] * weight;
                totalWeight += weight;
            }
        }

        if (!foundSamples || totalWeight == 0) { return linearPercent; }
        var learnedTarget = weightedSum / totalWeight;

        if (learnedTarget < linearPercent - 20) { learnedTarget = linearPercent - 20; }
        if (learnedTarget > linearPercent + 20) { learnedTarget = linearPercent + 20; }
        return learnedTarget;
    }

    function checkStepsAndAlert() as Void {
        var info = ActivityMonitor.getInfo();
        if (info == null || info.steps == null || info.stepGoal == null || info.stepGoal == 0) { return; }
        var settings = System.getDeviceSettings();
        if ((info has :isSleepMode && info.isSleepMode) || (settings has :doNotDisturb && settings.doNotDisturb)) { return; }
        
        var t = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        if (t.hour < 7 || t.hour >= 23) { return; }

        addHistoryRecord(info.steps, info.stepGoal);
        var expectedPct = getExpectedProgressForNow();
        var currentPct = (info.steps.toFloat() / info.stepGoal.toFloat()) * 100.0;
        
        if (currentPct - expectedPct < -5.0) {
            sendAlert("Lagging: " + (currentPct - expectedPct).format("%.1f") + "%");
        }
    }

    function addHistoryRecord(steps as Number, stepGoal as Number) as Void {
        if (_historyData == null) { _historyData = [] as Array<Array>; }
        var now = Time.now();
        var t = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var pct = (stepGoal > 0) ? (steps.toFloat() / stepGoal.toFloat()) * 100.0 : 0.0;

        _historyData.add([t.day_of_week, t.hour, pct, now.value()]);
        if (_historyData.size() > MAX_STORAGE_RECORDS) { _historyData = _historyData.slice(1, _historyData.size()); }
        saveHistoryData();
    }

    function sendAlert(message as Lang.String) as Void {
        if (Attention has :vibrate) { Attention.vibrate([new Attention.VibeProfile(100, 500)]); }
        if (System.getDeviceSettings().phoneConnected) {
            Communications.makeWebRequest("https://dummy.com", {"m"=>message}, {}, method(:onNotificationResponse));
        }
    }
    function onNotificationResponse(code as Number, data as Dictionary?) as Void {}
}

(:background)
class StepsServiceDelegate extends System.ServiceDelegate {
    function initialize() { ServiceDelegate.initialize(); }
    function onTemporalEvent() as Void {
        var app = Application.getApp() as steps_reminderApp;
        app.checkStepsAndAlert();
        Background.exit(null);
    }
}