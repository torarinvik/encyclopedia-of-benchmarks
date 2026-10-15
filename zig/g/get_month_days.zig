fn isLeapYear(year: i64) bool {
    return @rem(year, 400) == 0 or (@rem(year, 100) != 0 and @rem(year, 4) == 0);
}

/// Return the pinned JavaScript helper's month length.
export fn get_month_days(month_number: i64, year: i64) i64 {
    if (year < 0 or year > 9999) return -1;
    return switch (month_number) {
        1, 3, 5, 7, 8, 10, 12 => 31,
        4, 6, 9, 11 => 30,
        2 => if (isLeapYear(year)) 29 else 28,
        else => -1,
    };
}
