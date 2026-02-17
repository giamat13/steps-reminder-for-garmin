import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Timer;
import Toybox.Lang;

class steps_reminderView extends WatchUi.View {
    private var _line1 as Lang.String?;
    private var _line2 as Lang.String?;
    private var _deltaLabel as Lang.String?;
    private var _statusLabel as Lang.String?;
    private var _deltaValue as Float = 0.0;
    private var _updateTimer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _line1 = "";
        _line2 = "";
        _deltaLabel = "--";
        _statusLabel = "";
        _updateTimer = new Timer.Timer();
    }

    function onShow() as Void {
        if (_updateTimer != null) {
            _updateTimer.start(method(:requestUpdate), 30000, true);
        }
    }

    function onHide() as Void {
        if (_updateTimer != null) { _updateTimer.stop(); }
    }

    function requestUpdate() as Void {
        WatchUi.requestUpdate();
    }

    function updateLabels() as Void {
        var info = ActivityMonitor.getInfo();
        var app = Application.getApp() as steps_reminderApp;
        
        if (info != null && info.steps != null && info.stepGoal != null && info.stepGoal > 0) {
            _line1 = info.steps.toString() + " / " + info.stepGoal.toString();
            var currentPct = (info.steps.toFloat() / info.stepGoal.toFloat()) * 100.0;
            var expectedPct = app.getExpectedProgressForNow();
            _line2 = currentPct.format("%.1f") + "% | " + expectedPct.format("%.1f") + "%";
            _deltaValue = currentPct - expectedPct;
            var sign = (_deltaValue >= 0) ? "+" : "";
            _deltaLabel = sign + _deltaValue.format("%.1f") + "%";
            if (_deltaValue >= 0) {
                _statusLabel = "On Track";
            } else {
                _statusLabel = "Step now";
            }
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        updateLabels();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        // שימוש במיקומים יחסיים למניעת חפיפה
        // כותרת - 20% מגובה המסך
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.18, Graphics.FONT_XTINY, "Steps Monitor", Graphics.TEXT_JUSTIFY_CENTER);
        
        // שורה 1 (צעדים) - 32% מגובה המסך
        if (_line1 != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.30, Graphics.FONT_SMALL, _line1, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // שורה 2 (אחוזים קטנים) - 42% מגובה המסך
        if (_line2 != null) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.43, Graphics.FONT_XTINY, _line2, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // הדלתא המרכזית - 55% מגובה המסך
        if (_deltaLabel != null) {
            var color = (_deltaValue >= 0) ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            // החלפה לפונט LARGE במקום NUMBER - הרבה יותר נקי ב-AMOLED
            dc.drawText(cx, h * 0.55, Graphics.FONT_LARGE, _deltaLabel, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // סטטוס (Step Now) - 75% מגובה המסך
        if (_statusLabel != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.78, Graphics.FONT_MEDIUM, _statusLabel, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}