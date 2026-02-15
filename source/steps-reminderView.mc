import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.System;
import Toybox.Time;
import Toybox.Lang;

class steps_reminderView extends WatchUi.View {
    private var _stepsLabel as String?;
    private var _progressLabel as String?;

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // We'll draw custom UI instead of using layout XML
    }

    // Called when this View is brought to the foreground
    function onShow() as Void {
        updateLabels();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        updateLabels();
        
        // Clear the screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        
        // Draw title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height / 4, Graphics.FONT_MEDIUM, 
                   WatchUi.loadResource(Rez.Strings.AppName), 
                   Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw steps info
        if (_stepsLabel != null) {
            dc.drawText(centerX, height / 2 - 30, Graphics.FONT_SMALL, 
                       _stepsLabel, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Draw progress info
        if (_progressLabel != null) {
            dc.drawText(centerX, height / 2 + 10, Graphics.FONT_TINY, 
                       _progressLabel, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Draw status message
        var statusMsg = getStatusMessage();
        if (statusMsg != null) {
            var statusColor = statusMsg[:color];
            dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height * 3 / 4, Graphics.FONT_TINY, 
                       statusMsg[:text], Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Called when this View is removed from the screen
    function onHide() as Void {
    }

    private function updateLabels() as Void {
        var activityInfo = ActivityMonitor.getInfo();
        
        if (activityInfo == null) {
            _stepsLabel = WatchUi.loadResource(Rez.Strings.NoData);
            _progressLabel = "";
            return;
        }

        var currentSteps = activityInfo.steps;
        var stepGoal = activityInfo.stepGoal;
        
        if (currentSteps == null || stepGoal == null) {
            _stepsLabel = WatchUi.loadResource(Rez.Strings.NoData);
            _progressLabel = "";
            return;
        }

        // Format steps label
        _stepsLabel = Lang.format(WatchUi.loadResource(Rez.Strings.StepsFormat), 
                                 [currentSteps, stepGoal]);
        
        // Calculate progress
        var stepsPercent = ((currentSteps.toFloat() / stepGoal.toFloat()) * 100).toNumber();
        
        // Get time progress
        var now = Time.now();
        var timeInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var currentMinutes = timeInfo.hour * 60 + timeInfo.min;
        var totalMinutesInDay = 24 * 60;
        var timePercent = ((currentMinutes.toFloat() / totalMinutesInDay.toFloat()) * 100).toNumber();
        
        _progressLabel = Lang.format(WatchUi.loadResource(Rez.Strings.ProgressFormat), 
                                    [stepsPercent, timePercent]);
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

        // Get current time info
        var now = Time.now();
        var timeInfo = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var currentMinutes = timeInfo.hour * 60 + timeInfo.min;
        var totalMinutesInDay = 24 * 60;
        var dayProgress = currentMinutes.toFloat() / totalMinutesInDay.toFloat();

        // Get user settings
        var props = Application.Properties;
        var usePercent = props.getValue("usePercent");
        var timeThreshold = props.getValue("timeThreshold");
        var stepsThreshold = props.getValue("stepsThreshold");

        if (usePercent == null) { usePercent = true; }
        if (timeThreshold == null) { timeThreshold = 50; }
        if (stepsThreshold == null) { stepsThreshold = 50; }

        var isBehind = false;

        if (usePercent) {
            var timePercent = dayProgress * 100;
            var stepsPercent = (currentSteps.toFloat() / stepGoal.toFloat()) * 100;
            isBehind = (timePercent >= timeThreshold && stepsPercent < stepsThreshold);
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
