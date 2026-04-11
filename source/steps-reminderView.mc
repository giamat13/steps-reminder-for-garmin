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
        dc.drawRectangle(w*0.2, h*0.6, w*0.6, 12);
        dc.fillRectangle(w*0.2, h*0.6, (w*0.6) * (_progress/100.0), 12);
        dc.drawText(w/2, h*0.7, Graphics.FONT_XTINY, _progress + "%", 1);
    }
}

class MigrationDelegate extends WatchUi.BehaviorDelegate {
    function initialize() { BehaviorDelegate.initialize(); }
    function onBack() { System.exit(); return true; }
}

// --- מסך ראשי (Main View) ---
class steps_reminderView extends WatchUi.View {
    private var _displayData as Array<Dictionary> = [] as Array<Dictionary>;
    private var _currentScreen = 0;

    function initialize() { View.initialize(); }

    // פועל רק כשנכנסים למסך - חוסך סוללה משמעותית
    function onShow() {
        calculateData(true);
    }

    function nextScreen() as Void {
        if (_displayData.size() == 0) { return; }
        var nextIndex = (_currentScreen + 1) % _displayData.size();
        calculateData(false);
        if (_displayData.size() == 0) { return; }
        _currentScreen = nextIndex % _displayData.size();
        WatchUi.requestUpdate();
    }

    function buildScreen(title as String, current as Number, goal as Number, expectedPct as Float) as Dictionary {
        var curPct = (current.toFloat() / goal.toFloat()) * 100.0;
        var delta = curPct - expectedPct;

        return {
            "title" => title,
            "line1" => current.toString() + " / " + goal.toString(),
            "line2" => curPct.format("%.1f") + "% | " + expectedPct.format("%.1f") + "%",
            "delta" => ((delta >= 0) ? "+" : "") + delta.format("%.1f") + "%",
            "status" => (delta >= 0) ? "On Track" : "Move!",
            "color" => (delta >= 0) ? 0x00FF00 : 0xFF0000
        };
    }

    function calculateData(resetScreen as Boolean) {
        var info = ActivityMonitor.getInfo();
        var app = Application.getApp() as steps_reminderApp;
        _displayData = [] as Array<Dictionary>;
        if (resetScreen) {
            _currentScreen = 0;
        }
        
        if (info != null) {
            if (info.steps != null && info.stepGoal != null && info.stepGoal > 0) {
                _displayData.add(buildScreen("Steps Monitor", info.steps, info.stepGoal, app.getExpectedProgressForNow()));
            }

            if ((info has :floorsClimbed) && (info has :floorsClimbedGoal) && info.floorsClimbed != null && info.floorsClimbedGoal != null && info.floorsClimbedGoal > 0) {
                _displayData.add(buildScreen("Floors", info.floorsClimbed, info.floorsClimbedGoal, app.getLinearExpectedProgressForNow()));
            }
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) {
        dc.setColor(0x000000, 0x000000); dc.clear();
        if (_displayData.size() == 0) { return; }

        var screen = _displayData[_currentScreen];
        var cx = dc.getWidth() / 2, h = dc.getHeight();

        dc.setColor(0xAAAAAA, -1);
        dc.drawText(cx, h * 0.12, Graphics.FONT_XTINY, screen["title"], 1);
        dc.drawText(cx, h * 0.20, Graphics.FONT_XTINY, (_currentScreen + 1).toString() + "/" + _displayData.size().toString(), 1);

        dc.setColor(0xFFFFFF, -1);
        dc.drawText(cx, h * 0.32, Graphics.FONT_SMALL, screen["line1"], 1);
        dc.setColor(0xAAAAAA, -1);
        dc.drawText(cx, h * 0.45, Graphics.FONT_XTINY, screen["line2"], 1);
        dc.setColor(screen["color"], -1);
        dc.drawText(cx, h * 0.57, Graphics.FONT_LARGE, screen["delta"], 1);
        dc.setColor(0xFFFFFF, -1);
        dc.drawText(cx, h * 0.77, Graphics.FONT_MEDIUM, screen["status"], 1);
    }
}

class steps_reminderDelegate extends WatchUi.BehaviorDelegate {
    private var _view as steps_reminderView;

    function initialize(view as steps_reminderView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        _view.nextScreen();
        return true;
    }
}
