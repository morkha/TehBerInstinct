using Toybox.WatchUi as WatchUi;
using Toybox.Graphics as Graphics;
using Toybox.System as System;
using Toybox.Application as App;
using Toybox.Activity as Activity;
using Toybox.Time as Time;

class WatchFace extends WatchUi.WatchFace {

    var altMode = false;

    function initialize() {
        WatchUi.WatchFace.initialize();

        var saved = App.getApp().getProperty("altMode");
        altMode = (saved != null) ? saved : false;
        App.getApp().setProperty("altMode", altMode);
    }

    function onKeyLong(key) {
        if (key == WatchUi.KEY_MENU) {
            altMode = !altMode;
            App.getApp().setProperty("altMode", altMode);
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    function onUpdate(dc) {
        dc.clear();

        // ---- Time ----
        var now = System.getClockTime();
        var hourTeh = now.hour;
        var min = now.min;
        var minStr = min < 10 ? "0" + min : min;

        // ---- Berlin ----
        var dstOn = App.getApp().getProperty("berlinDST");
        var offset = dstOn ? -1.5 : -2.5;

        var hourBer = hourTeh + offset;
        var minBer = min;

        if (offset % 1 != 0) {
            minBer -= 30;
            if (minBer < 0) {
                minBer += 60;
                hourBer -= 1;
            }
        }
        if (hourBer < 0) hourBer += 24;
        if (hourBer >= 24) hourBer -= 24;

        var minBerStr = minBer < 10 ? "0" + minBer : minBer;

        // ---- Date ----
        var g = Time.Gregorian.info(Time.now(), Time.FORMAT_LONG);
        var gDateStr = g.year + "." + g.month + "." + g.day;

        var j = gregorianToJalali(g.year, g.month, g.day);
        var jDateStr = j.year + "." + j.month + "." + j.day;

        // ---- Weekday (sub-dial) ----
        var weekDays = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
        var weekDayStr = weekDays[g.dayOfWeek];

        // ---- Battery & Steps ----
        var battery = System.getSystemStats().battery;
        var steps = Activity.getInfo().steps;
        if (steps == null) steps = 0;

        // ---- UI ----
        if (!altMode) {
            // Normal mode
            dc.drawText(88, 38, Graphics.FONT_SMALL, weekDayStr, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(88, 60, Graphics.FONT_SMALL, jDateStr, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(88, 90, Graphics.FONT_MEDIUM,
                "TEH " + hourTeh + ":" + minStr,
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(88, 115, Graphics.FONT_SMALL,
                "STP " + steps,
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(88, 140, Graphics.FONT_SMALL,
                "BAT " + battery + "%",
                Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            // Alternate mode
            dc.drawText(88, 38, Graphics.FONT_SMALL, weekDayStr, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(88, 60, Graphics.FONT_SMALL, gDateStr, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(88, 90, Graphics.FONT_MEDIUM,
                "TEH " + hourTeh + ":" + minStr,
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(88, 115, Graphics.FONT_MEDIUM,
                "BER " + hourBer + ":" + minBerStr,
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(88, 140, Graphics.FONT_SMALL,
                "BAT " + battery + "%",
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

// ---- Gregorian → Jalali ----
function gregorianToJalali(gy, gm, gd) {
    var g_d_m = [0,31,59,90,120,151,181,212,243,273,304,334];
    var jy = (gy > 1600) ? 979 : 0;
    gy -= (gy > 1600) ? 1600 : 621;

    var gy2 = (gm > 2) ? (gy + 1) : gy;
    var days = 365 * gy
        + ((gy2 + 3) / 4).floor()
        - ((gy2 + 99) / 100).floor()
        + ((gy2 + 399) / 400).floor()
        - 80 + gd + g_d_m[gm - 1];

    jy += 33 * (days / 12053).floor();
    days %= 12053;

    jy += 4 * (days / 1461).floor();
    days %= 1461;

    if (days > 365) {
        jy += ((days - 1) / 365).floor();
        days = (days - 1) % 365;
    }

    var jm = (days < 186) ? 1 + (days / 31).floor() : 7 + ((days - 186) / 30).floor();
    var jd = 1 + ((days < 186) ? (days % 31) : ((days - 186) % 30));

    return { year: jy, month: jm, day: jd };
}
