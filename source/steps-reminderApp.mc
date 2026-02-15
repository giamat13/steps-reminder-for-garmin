import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Background;
import Toybox.System;
import Toybox.Time;
import Toybox.ActivityMonitor;
import Toybox.Attention;

class steps_reminderApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        // Register for temporal events to check steps periodically
        Background.registerForTemporalEvent(new Time.Duration(5 * 60)); // Check every 5 minutes
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        Background.deleteTemporalEvent();
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new steps_reminderView() ];
    }

    // Service delegate
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new StepsServiceDelegate()];
    }

    // Check if user is behind on steps
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

        var shouldAlert = false;
        var alertMessage = "";

        if (usePercent) {
            // Percentage mode
            var timePercent = dayProgress * 100;
            var stepsPercent = (currentSteps.toFloat() / stepGoal.toFloat()) * 100;
            
            if (timePercent >= timeThreshold && stepsPercent < stepsThreshold) {
                shouldAlert = true;
                alertMessage = WatchUi.loadResource(Rez.Strings.AlertMessagePercent);
                alertMessage = Lang.format(alertMessage, 
                                          [timePercent.format("%d"), stepsPercent.format("%d")]);
            }
        } else {
            // Absolute mode
            if (currentMinutes >= timeThreshold && currentSteps < stepsThreshold) {
                shouldAlert = true;
                var hoursElapsed = (currentMinutes / 60).format("%d");
                var minutesElapsed = (currentMinutes % 60).format("%02d");
                alertMessage = WatchUi.loadResource(Rez.Strings.AlertMessageAbsolute);
                alertMessage = Lang.format(alertMessage, 
                                          [hoursElapsed, minutesElapsed, currentSteps, stepsThreshold]);
            }
        }

        if (shouldAlert) {
            sendAlert(alertMessage);
        }
    }

    function sendAlert(message as String) as Void {
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
