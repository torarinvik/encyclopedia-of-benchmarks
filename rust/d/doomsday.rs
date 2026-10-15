/// Gregorian weekday from Conway's Doomsday rule.
#[no_mangle]
pub extern "C" fn doomsday(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 3 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let year = values[0];
    let month = values[1];
    let day = values[2];
    if year < 100 || year > 9999 || month < 1 || month > 12 { return -1; }
    let leap = year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
    let days_in_month = if month == 2 {
        if leap { 29 } else { 28 }
    } else if month == 4 || month == 6 || month == 9 || month == 11 {
        30
    } else {
        31
    };
    if day < 1 || day > days_in_month { return -1; }

    let within_century = year % 100;
    let century_anchor = (5 * ((year / 100) % 4) + 2) % 7;
    let doom = (within_century / 12 + within_century % 12
        + (within_century % 12) / 4 + century_anchor) % 7;
    let anchor = match month {
        1 => if leap { 4 } else { 3 },
        2 => if leap { 1 } else { 7 },
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
        _ => return -1,
    };
    let mut weekday = (doom + day - anchor) % 7;
    if weekday < 0 { weekday += 7; }
    weekday
}
