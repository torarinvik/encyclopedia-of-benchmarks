/// Return the Gregorian weekday for `[year, month, day]`; Sunday is zero.
#[no_mangle]
pub extern "C" fn zellers_congruence(date: *const i64, length: usize) -> i64 {
    if date.is_null() || length != 3 { return -1; }
    let date = unsafe { std::slice::from_raw_parts(date, length) };
    let (mut year, mut month, day) = (date[0], date[1], date[2]);
    if !(46..=8499).contains(&year) || !(1..=12).contains(&month) || day < 1 { return -1; }
    let days_by_month = [31i64, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    let leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
    let maximum_day = days_by_month[(month - 1) as usize] + if month == 2 && leap { 1 } else { 0 };
    if day > maximum_day { return -1; }

    if month <= 2 { year -= 1; month += 12; }
    let century = year / 100;
    let year_of_century = year % 100;
    let month_term = (260 * month - 539) / 100;
    let total = day + year_of_century + month_term + century / 4 +
                year_of_century / 4 - 2 * century;
    total.rem_euclid(7)
}
