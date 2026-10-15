/// Gregorian weekday by the pinned Rust month-offset recurrence.
const MONTH_OFFSETS = [_]i64{ 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4 };

fn isLeapYear(year: i64) bool {
    return @mod(year, 400) == 0 or (@mod(year, 4) == 0 and @mod(year, 100) != 0);
}

export fn weekday_by_month_offsets(values: [*]const i64, length: usize) i64 {
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

    const adjusted_year = year - (if (month < 3) @as(i64, 1) else 0);
    const offset = MONTH_OFFSETS[@intCast(month - 1)];
    return @mod(adjusted_year + @divTrunc(adjusted_year, 4)
        - @divTrunc(adjusted_year, 100) + @divTrunc(adjusted_year, 400)
        + offset + day, 7);
}
