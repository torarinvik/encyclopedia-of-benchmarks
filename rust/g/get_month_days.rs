fn is_leap_year(year: i64) -> bool {
    year % 400 == 0 || (year % 100 != 0 && year % 4 == 0)
}

/// Return the pinned JavaScript helper's month length.
#[no_mangle]
pub extern "C" fn get_month_days(month_number: i64, year: i64) -> i64 {
    if !(0..=9999).contains(&year) {
        return -1;
    }
    match month_number {
        1 | 3 | 5 | 7 | 8 | 10 | 12 => 31,
        4 | 6 | 9 | 11 => 30,
        2 => if is_leap_year(year) { 29 } else { 28 },
        _ => -1,
    }
}
