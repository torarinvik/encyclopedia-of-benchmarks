fn is_leap_year(year: i64) -> bool {
    year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)
}

/// Count months beginning on Sunday from January 1901 through December 2000.
#[no_mangle]
pub extern "C" fn problem19(ignored: i64) -> i64 {
    if ignored != 0 {
        return -1;
    }
    let mut weekday = 2_i64; // 1 January 1901 was Tuesday; Sunday is 0.
    let mut count = 0_i64;
    for year in 1901..=2000 {
        for month in 1..=12 {
            if weekday == 0 {
                count += 1;
            }
            let days = match month {
                4 | 6 | 9 | 11 => 30,
                2 if is_leap_year(year) => 29,
                2 => 28,
                _ => 31,
            };
            weekday = (weekday + days) % 7;
        }
    }
    count
}
