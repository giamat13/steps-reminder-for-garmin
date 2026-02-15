import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.System;
import Toybox.Time;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.Application;

class steps_reminderView extends WatchUi.View {
    private var _stepsLabel as String?;
    private var _progressLabel as String?;
    private var _learningLabel as String?;
    private var _updateTimer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _updateTimer = new Timer.Timer();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        updateLabels();
        
        if (_updateTimer != null) {
            _updateTimer.start(method(:timerCallback), 10000, true);
        }
    }

    function onHide() as Void {
        if (_updateTimer != null) {
            _updateTimer.stop();
        }
    }

    function timerCallback() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        updateLabels();
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        
        // כותרת
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height / 6, Graphics.FONT_MEDIUM, 
                   WatchUi.loadResource(Rez.Strings.AppName), 
                   Graphics.TEXT_JUSTIFY_CENTER);
        
        // מידע על צעדים
        if (_stepsLabel != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height / 2 - 40, Graphics.FONT_SMALL, 
                       _stepsLabel, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // התקדמות
        if (_progressLabel != null) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height / 2, Graphics.FONT_TINY, 
                       _progressLabel, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // מידע למידה
        if (_learningLabel != null) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height / 2 + 30, Graphics.FONT_XTINY, 
                       _learningLabel, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // סטטוס
        var statusMsg = getStatusMessage();
        if (statusMsg != null) {
            var statusColor = statusMsg[:color];
            dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height * 5 / 6, Graphics.FONT_SMALL, 
                       statusMsg[:text], Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    private function updateLabels() as Void {
        var activityInfo = ActivityMonitor.getInfo();
        
        if (activityInfo == null) {
            _stepsLabel = WatchUi.loadResource(Rez.Strings.NoData);
            _progressLabel = "";
            _learningLabel = "";
            return;
        }

        var currentSteps = activityInfo.steps;
        var stepGoal = activityInfo.stepGoal;
        
        if (currentSteps == null || stepGoal == null) {
            _stepsLabel = WatchUi.loadResource(Rez.Strings.NoData);
            _progressLabel = "";
            _learningLabel = "";
            return;
        }

        _stepsLabel = Lang.format(WatchUi.loadResource(Rez.Strings.StepsFormat), 
                                 [currentSteps, stepGoal]);
        
        var stepsPercent = ((currentSteps.toFloat() / stepGoal.toFloat()) * 100).toNumber();
        
        var now = Time.now();
        var timeInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var currentMinutes = timeInfo.hour * 60 + timeInfo.min;
        var totalMinutesInDay = 24 * 60;
        var timePercent = ((currentMinutes.toFloat() / totalMinutesInDay.toFloat()) * 100).toNumber();
        
        _progressLabel = Lang.format(WatchUi.loadResource(Rez.Strings.ProgressFormat), 
                                    [stepsPercent, timePercent]);
        
        // הצגת מידע על למידה
        var app = Application.getApp() as steps_reminderApp;
        var expectedProgress = app.getExpectedProgressForNow();
        var diff = stepsPercent - expectedProgress;
        
        if (diff >= 0) {
            _learningLabel = Lang.format("Expected: $1$% (+$2$%)", 
                                        [expectedProgress.format("%.0f"), diff.format("%.0f")]);
        } else {
            _learningLabel = Lang.format("Expected: $1$% ($2$%)", 
                                        [expectedProgress.format("%.0f"), diff.format("%.0f")]);
        }
    }

    private function getStatusMessage() as Dictionary? {
        var activityInfo = ActivityMonitor.getInfo();
        
        if (activityInfo == null) {
            return null;
        }

        var currentSteps = activityInfo.steps;
        var stepGoal = activityInfo.stepGoal;
        
        if (currentSteps == null || stepGoal == null || stepGoal == 0) {
            return null;
        }

        var now = Time.now();
        var timeInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var currentMinutes = timeInfo.hour * 60 + timeInfo.min;
        var totalMinutesInDay = 24 * 60;
        var dayProgress = currentMinutes.toFloat() / totalMinutesInDay.toFloat();
        var stepsPercent = (currentSteps.toFloat() / stepGoal.toFloat()) * 100;

        var props = Application.Properties;
        var usePercent = props.getValue("usePercent");
        var timeThreshold = props.getValue("timeThreshold");
        var stepsThreshold = props.getValue("stepsThreshold");

        if (usePercent == null) { usePercent = true; }
        if (timeThreshold == null) { timeThreshold = 50; }
        if (stepsThreshold == null) { stepsThreshold = 50; }

        var isBehind = false;

        if (usePercent) {
            // שימוש בלמידה
            var app = Application.getApp() as steps_reminderApp;
            var expectedProgress = app.getExpectedProgressForNow();
            isBehind = (stepsPercent < expectedProgress - 5);
        } else {
            isBehind = (currentMinutes >= timeThreshold && currentSteps < stepsThreshold);
        }

        if (isBehind) {
            return {
                :text => WatchUi.loadResource(Rez.Strings.StatusBehind),
                :color => Graphics.COLOR_RED
            };
        } else {
            return {
                :text => WatchUi.loadResource(Rez.Strings.StatusOnTrack),
                :color => Graphics.COLOR_GREEN
            };
        }
    }
}
