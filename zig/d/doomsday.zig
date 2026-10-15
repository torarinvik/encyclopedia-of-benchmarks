/// Gregorian weekday from Conway's Doomsday rule.
fn isLeapYear(year: i64) bool {
    return @mod(year, 400) == 0 or (@mod(year, 4) == 0 and @mod(year, 100) != 0);
}

fn monthAnchor(month: i64, leap: bool) i64 {
    return switch (month) {
        1 => if (leap) 4 else 3,
        2 => if (leap) 1 else 7,
        3 => 7,
        4 => 4,
        5 => 2,
        6 => 6,
        7 => 4,
        8 => 1,
        9 => 5,
        10 => 3,
        11 => 7,
        12 => 5,
        else => -1,
    };
}

export fn doomsday(values: [*]const i64, length: usize) i64 {
    if (length != 3) return -1;
    const year = values[0];
    const month = values[1];
    const day = values[2];
    if (year < 100 or year > 9999 or month < 1 or month > 12) return -1;
    const leap = isLeapYear(year);
    const days_in_month: i64 = if (month == 2)
        (if (leap) 29 else 28)
    else if (month == 4 or month == 6 or month == 9 or month == 11)
        30
    else
        31;
    if (day < 1 or day > days_in_month) return -1;

    const within_century = @mod(year, 100);
    const century_anchor = @mod(5 * (@mod(@divTrunc(year, 100), 4)) + 2, 7);
    const doom = @mod(@divTrunc(within_century, 12) + @mod(within_century, 12)
        + @divTrunc(@mod(within_century, 12), 4) + century_anchor, 7);
    const raw_weekday = @mod(doom + day - monthAnchor(month, leap), 7);
    return if (raw_weekday < 0) raw_weekday + 7 else raw_weekday;
}
