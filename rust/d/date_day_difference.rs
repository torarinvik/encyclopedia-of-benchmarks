/// Absolute difference between two validated Gregorian dates.
const MAX_LENGTH: usize = 21;

fn floor_div(value: i64, divisor: i64) -> i64 {
    let quotient = value / divisor;
    if value % divisor != 0 && value < 0 { quotient - 1 } else { quotient }
}

fn leap_year(year: i64) -> bool {
    year % 400 == 0 || (year % 100 != 0 && year % 4 == 0)
}

fn month_length(month: i64, year: i64) -> i64 {
    match month {
        2 => if leap_year(year) { 29 } else { 28 },
        4 | 6 | 9 | 11 => 30,
        _ => 31,
    }
}

fn date_ordinal(day: i64, month: i64, year: i64) -> i64 {
    let prior = year - 1;
    let adjustment = if month <= 2 { 0 } else if leap_year(year) { -1 } else { -2 };
    365 * prior + floor_div(prior, 4) - floor_div(prior, 100) + floor_div(prior, 400) +
        day + floor_div(367 * month - 362, 12) + adjustment
}

fn parse_date(values: *const i64, start: usize, end: usize) -> Option<i64> {
    let mut pos = start;
    let mut day = 0i64;
    let mut month = 0i64;
    let mut year = 0i64;
    let mut digits = 0usize;
    while pos < end && unsafe { *values.add(pos) } >= 48 && unsafe { *values.add(pos) } <= 57 && digits < 3 {
        day = day * 10 + unsafe { *values.add(pos) } - 48;
        digits += 1;
        pos += 1;
    }
    if digits == 0 || digits > 2 || pos >= end || unsafe { *values.add(pos) } != 47 { return None; }
    pos += 1;
    digits = 0;
    while pos < end && unsafe { *values.add(pos) } >= 48 && unsafe { *values.add(pos) } <= 57 && digits < 3 {
        month = month * 10 + unsafe { *values.add(pos) } - 48;
        digits += 1;
        pos += 1;
    }
    if digits == 0 || digits > 2 || pos >= end || unsafe { *values.add(pos) } != 47 { return None; }
    pos += 1;
    if end - pos != 4 { return None; }
    while pos < end {
        let value = unsafe { *values.add(pos) };
        if !(48..=57).contains(&value) { return None; }
        year = year * 10 + value - 48;
        pos += 1;
    }
    if !(1..=12).contains(&month) || day < 1 || day > month_length(month, year) { return None; }
    Some(date_ordinal(day, month, year))
}

#[no_mangle]
pub extern "C" fn date_day_difference(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(17..=MAX_LENGTH).contains(&length) { return -1; }
    let mut separator = length;
    for index in 0..length {
        if unsafe { *values.add(index) } == 124 {
            if separator != length { return -1; }
            separator = index;
        }
    }
    if separator == length { return -1; }
    let Some(first) = parse_date(values, 0, separator) else { return -1; };
    let Some(second) = parse_date(values, separator + 1, length) else { return -1; };
    (first - second).abs()
}
