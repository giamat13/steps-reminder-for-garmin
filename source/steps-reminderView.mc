import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Timer;
import Toybox.Lang;

class steps_reminderView extends WatchUi.View {
    // משתנים לתצוגה - מוגדרים כ-Nullable כדי למנוע שגיאות אתחול
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
        // רענון המסך כל 30 שניות כשהאפליקציה פתוחה
        if (_updateTimer != null) {
            _updateTimer.start(method(:requestUpdate), 30000, true);
        }
    }

    function onHide() as Void {
        if (_updateTimer != null) { _updateTimer.stop(); }
    }

    // פונקציית עזר לטיימר
    function requestUpdate() as Void {
        WatchUi.requestUpdate();
    }

    function updateLabels() as Void {
        var info = ActivityMonitor.getInfo();
        var app = Application.getApp() as steps_reminderApp;
        
        if (info != null && info.steps != null && info.stepGoal != null && info.stepGoal > 0) {
            
            // שורה 1: צעדים / יעד
            _line1 = info.steps.toString() + " / " + info.stepGoal.toString();
            
            // חישובים
            var currentPct = (info.steps.toFloat() / info.stepGoal.toFloat()) * 100.0;
            var expectedPct = app.getExpectedProgressForNow();
            
            // שורה 2: אחוז נוכחי | אחוז יעד (לפי למידה)
            _line2 = currentPct.format("%.1f") + "% | " + expectedPct.format("%.1f") + "%";
            
            // חישוב הדלתא ("האחד העליון")
            _deltaValue = currentPct - expectedPct;
            var sign = (_deltaValue >= 0) ? "+" : "";
            _deltaLabel = sign + _deltaValue.format("%.1f") + "%";
            
            // סטטוס טקסטואלי
            if (_deltaValue >= 0) {
                _statusLabel = "On Track";
            } else {
                _statusLabel = "Step now";
            }
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        // קודם מחשבים את המספרים
        updateLabels();

        // ניקוי מסך
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        
        // כותרת קטנה
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 80, Graphics.FONT_XTINY, "Steps Monitor", Graphics.TEXT_JUSTIFY_CENTER);
        
        // שורה 1 (צעדים/יעד)
        if (_line1 != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 55, Graphics.FONT_SMALL, _line1, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // שורה 2 (אחוזים)
        if (_line2 != null) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 30, Graphics.FONT_XTINY, _line2, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // הדלתא ("האחד העליון") - בגדול ובצבע
        if (_deltaLabel != null) {
            // ירוק אם חיובי (או אפס), אדום אם שלילי
            var color = (_deltaValue >= 0) ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            // שימוש בפונט גדול למספר המרכזי
            dc.drawText(cx, cy + 5, Graphics.FONT_NUMBER_MEDIUM, _deltaLabel, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // סטטוס (On Track / Step Now)
        if (_statusLabel != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + 55, Graphics.FONT_MEDIUM, _statusLabel, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}