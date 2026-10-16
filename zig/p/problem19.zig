fn is_leap_year(year: i64) bool {
    return @mod(year, 400) == 0 or (@mod(year, 4) == 0 and @mod(year, 100) != 0);
}

export fn problem19(ignored: i64) i64 {
    if (ignored != 0) return -1;
    var weekday: i64 = 2; // 1 January 1901 was Tuesday; Sunday is 0.
    var count: i64 = 0;
    var year: i64 = 1901;
    while (year <= 2000) : (year += 1) {
        var month: i64 = 1;
        while (month <= 12) : (month += 1) {
            if (weekday == 0) count += 1;
            var days: i64 = 31;
            if (month == 4 or month == 6 or month == 9 or month == 11) days = 30;
            if (month == 2) days = if (is_leap_year(year)) 29 else 28;
            weekday = @mod(weekday + days, 7);
        }
    }
    return count;
}
