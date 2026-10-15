/// Return 1 for a positive Gregorian leap year, 0 otherwise, or -1 for invalid years.
#[no_mangle]
pub extern "C" fn leap_year(year: i64) -> i64 {
    if year <= 0 { return -1; }
    (year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)) as i64
}
