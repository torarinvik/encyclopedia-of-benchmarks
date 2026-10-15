/// Gregorian weekday by the pinned Rust month-offset recurrence.
const MONTH_OFFSETS: [i64; 12] = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4];

fn is_leap_year(year: i64) -> bool {
    year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)
}

#[no_mangle]
pub extern "C" fn weekday_by_month_offsets(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 3 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let year = values[0];
    let month = values[1];
    let day = values[2];
    if year < 100 || year > 9999 || month < 1 || month > 12 { return -1; }
    let leap = is_leap_year(year);
    let days_in_month = if month == 2 {
        if leap { 29 } else { 28 }
    } else if month == 4 || month == 6 || month == 9 || month == 11 {
        30
    } else {
        31
    };
    if day < 1 || day > days_in_month { return -1; }

    let adjusted_year = if month < 3 { year - 1 } else { year };
    (adjusted_year + adjusted_year / 4 - adjusted_year / 100
        + adjusted_year / 400 + MONTH_OFFSETS[(month - 1) as usize] + day) % 7
}
