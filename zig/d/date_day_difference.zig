/// Absolute difference between two validated Gregorian dates.
const MAX_LENGTH: usize = 21;
const INVALID_ORDINAL: i64 = -1000000000;

fn floor_div(value: i64, divisor: i64) i64 {
    const quotient = @divTrunc(value, divisor);
    if (@rem(value, divisor) != 0 and value < 0) return quotient - 1;
    return quotient;
}

fn leap_year(year: i64) bool {
    return @rem(year, 400) == 0 or (@rem(year, 100) != 0 and @rem(year, 4) == 0);
}

fn month_length(month: i64, year: i64) i64 {
    if (month == 2) return if (leap_year(year)) 29 else 28;
    if (month == 4 or month == 6 or month == 9 or month == 11) return 30;
    return 31;
}

fn date_ordinal(day: i64, month: i64, year: i64) i64 {
    const prior = year - 1;
    const adjustment: i64 = if (month <= 2) 0 else if (leap_year(year)) -1 else -2;
    return 365 * prior + floor_div(prior, 4) - floor_div(prior, 100) + floor_div(prior, 400) +
        day + floor_div(367 * month - 362, 12) + adjustment;
}

fn parse_date(values: [*]const i64, start: usize, end: usize) i64 {
    var pos = start;
    var day: i64 = 0;
    var month: i64 = 0;
    var year: i64 = 0;
    var digits: usize = 0;
    while (pos < end and values[pos] >= 48 and values[pos] <= 57 and digits < 3) : (pos += 1) {
        day = day * 10 + values[pos] - 48;
        digits += 1;
    }
    if (digits == 0 or digits > 2 or pos >= end or values[pos] != 47) return INVALID_ORDINAL;
    pos += 1;
    digits = 0;
    while (pos < end and values[pos] >= 48 and values[pos] <= 57 and digits < 3) : (pos += 1) {
        month = month * 10 + values[pos] - 48;
        digits += 1;
    }
    if (digits == 0 or digits > 2 or pos >= end or values[pos] != 47) return INVALID_ORDINAL;
    pos += 1;
    if (end - pos != 4) return INVALID_ORDINAL;
    while (pos < end) : (pos += 1) {
        if (values[pos] < 48 or values[pos] > 57) return INVALID_ORDINAL;
        year = year * 10 + values[pos] - 48;
    }
    if (month < 1 or month > 12 or day < 1 or day > month_length(month, year)) return INVALID_ORDINAL;
    return date_ordinal(day, month, year);
}

/// Return the absolute day difference; malformed packed dates return -1.
export fn date_day_difference(values: [*]const i64, length: usize) i64 {
    if (length < 17 or length > MAX_LENGTH) return -1;
    var separator = length;
    for (0..length) |index| {
        if (values[index] == 124) {
            if (separator != length) return -1;
            separator = index;
        }
    }
    if (separator == length) return -1;
    const first = parse_date(values, 0, separator);
    const second = parse_date(values, separator + 1, length);
    if (first == INVALID_ORDINAL or second == INVALID_ORDINAL) return -1;
    return if (first > second) first - second else second - first;
}
