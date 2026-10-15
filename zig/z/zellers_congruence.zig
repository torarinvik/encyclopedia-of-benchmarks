/// Return the Gregorian weekday for `[year, month, day]`; Sunday is zero.
fn isLeapYear(year: i64) bool {
    return @rem(year, 4) == 0 and (@rem(year, 100) != 0 or @rem(year, 400) == 0);
}

export fn zellers_congruence(date: [*]const i64, length: usize) i64 {
    if (length != 3) return -1;
    var year = date[0];
    var month = date[1];
    const day = date[2];
    if (year < 46 or year > 8499 or month < 1 or month > 12 or day < 1) return -1;
    var maximum_day: i64 = 31;
    if (month == 4 or month == 6 or month == 9 or month == 11) maximum_day = 30;
    if (month == 2) maximum_day = if (isLeapYear(year)) 29 else 28;
    if (day > maximum_day) return -1;

    if (month <= 2) { year -= 1; month += 12; }
    const century = @divTrunc(year, 100);
    const year_of_century = @rem(year, 100);
    const month_term = @divTrunc(260 * month - 539, 100);
    const total = day + year_of_century + month_term + @divTrunc(century, 4) +
                  @divTrunc(year_of_century, 4) - 2 * century;
    return @mod(total, 7);
}
