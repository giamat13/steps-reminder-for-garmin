import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Timer;
import Toybox.Lang;

// --- מסך הגירה (Migration) ---
class MigrationView extends WatchUi.View {
    private var _oldData as Array;
    private var _newData as Array<Array> = [] as Array<Array>;
    private var _currentIndex = 0;
    private var _batchSize = 25;
    private var _progress = 0;
    private var _timer as Timer.Timer = new Timer.Timer();

    function initialize(data as Array) {
        View.initialize();
        _oldData = data;
    }

    function onShow() { _timer.start(method(:processBatch), 50, true); }

    function processBatch() as Void {
        var end = _currentIndex + _batchSize;
        if (end > _oldData.size()) { end = _oldData.size(); }

        for (var i = _currentIndex; i < end; i++) {
            var item = _oldData[i];
            if (item instanceof Dictionary) {
                _newData.add([item["day"], item["hour"], item["stepsPercent"], item["timestamp"]]);
            }
            _currentIndex++;
        }

        _progress = (_currentIndex.toFloat() / _oldData.size().toFloat() * 100).toNumber();
        WatchUi.requestUpdate();

        if (_currentIndex >= _oldData.size()) {
            _timer.stop();
            (Application.getApp() as steps_reminderApp).finishMigration(_newData);
        }
    }

    function onUpdate(dc as Graphics.Dc) {
        dc.setColor(0x000000, 0x000000); dc.clear();
        var w = dc.getWidth(), h = dc.getHeight();
        dc.setColor(0xFFFFFF, -1);
        dc.drawText(w/2, h*0.3, Graphics.FONT_SMALL, "Updating Database", 1);
        dc.drawText(w/2, h*0.45, Graphics.FONT_XTINY, "Please wait...", 1);
        
        dc.drawRectangle(w*0.2, h*0.6, w*0.6, 12);
        dc.fillRectangle(w*0.2, h*0.6, (w*0.6) * (_progress/100.0), 12);
        dc.drawText(w/2, h*0.7, Graphics.FONT_XTINY, _progress + "%", 1);
        dc.drawText(w/2, h*0.85, Graphics.FONT_XTINY, "Back to Exit", 1);
    }
}

class MigrationDelegate extends WatchUi.BehaviorDelegate {
    function initialize() { BehaviorDelegate.initialize(); }
    function onBack() { System.exit(); return true; }
}

// --- מסך ראשי (Main View) ---
class steps_reminderView extends WatchUi.View {
    private var _line1 = "", _line2 = "", _deltaLabel = "--", _statusLabel = "";
    private var _deltaValue = 0.0;
    private var _updateTimer = new Timer.Timer();

    function initialize() { View.initialize(); }
    function onShow() { _updateTimer.start(method(:requestUpdate), 30000, true); }
    function onHide() { _updateTimer.stop(); }
    function requestUpdate() { WatchUi.requestUpdate(); }

    function onUpdate(dc as Graphics.Dc) {
        var info = ActivityMonitor.getInfo();
        var app = Application.getApp() as steps_reminderApp;
        
        if (info != null && info.steps != null && info.stepGoal != null && info.stepGoal > 0) {
            var curPct = (info.steps.toFloat() / info.stepGoal.toFloat()) * 100.0;
            var expPct = app.getExpectedProgressForNow();
            _line1 = info.steps.toString() + " / " + info.stepGoal.toString();
            _line2 = curPct.format("%.1f") + "% | " + expPct.format("%.1f") + "%";
            _deltaValue = curPct - expPct;
            _deltaLabel = ((_deltaValue >= 0) ? "+" : "") + _deltaValue.format("%.1f") + "%";
            _statusLabel = (_deltaValue >= 0) ? "On Track" : "Step now";
        }

        dc.setColor(0x000000, 0x000000); dc.clear();
        var cx = dc.getWidth() / 2, h = dc.getHeight();

        dc.setColor(0xAAAAAA, -1);
        dc.drawText(cx, h * 0.18, Graphics.FONT_XTINY, "Steps Monitor", 1);
        dc.setColor(0xFFFFFF, -1);
        dc.drawText(cx, h * 0.30, Graphics.FONT_SMALL, _line1, 1);
        dc.setColor(0xAAAAAA, -1);
        dc.drawText(cx, h * 0.43, Graphics.FONT_XTINY, _line2, 1);
        dc.setColor((_deltaValue >= 0) ? 0x00FF00 : 0xFF0000, -1);
        dc.drawText(cx, h * 0.55, Graphics.FONT_LARGE, _deltaLabel, 1);
        dc.setColor(0xFFFFFF, -1);
        dc.drawText(cx, h * 0.78, Graphics.FONT_MEDIUM, _statusLabel, 1);
    }
}