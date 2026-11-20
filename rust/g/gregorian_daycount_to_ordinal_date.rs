fn is_leap_year(year: i64) -> bool {
    year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

fn decode_offset(offset: i64) -> (i64, i64) {
    let shifted = offset + 719468;
    let era = shifted / 146097;
    let day_of_era = shifted - era * 146097;
    let year_of_era = (day_of_era - day_of_era / 1460 + day_of_era / 36524
        - day_of_era / 146096) / 365;
    let mut year = year_of_era + era * 400;
    let day_of_year_march = day_of_era
        - (365 * year_of_era + year_of_era / 4 - year_of_era / 100);
    let month_march = (5 * day_of_year_march + 2) / 153;
    let day = day_of_year_march - (153 * month_march + 2) / 5 + 1;
    let month = month_march + if month_march < 10 { 3 } else { -9 };
    if month <= 2 { year += 1; }
    const DAYS_BEFORE_MONTH: [i64; 12] = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    let leap_adjustment = if month > 2 && is_leap_year(year) { 1 } else { 0 };
    (year, DAYS_BEFORE_MONTH[(month - 1) as usize] + leap_adjustment + day)
}

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        output[offset + byte] = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn gregorian_daycount_to_ordinal_date(
    raw: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if raw.is_null() || !(1..=2).contains(&length) || length != 1 {
        return -1;
    }
    let input = std::slice::from_raw_parts(raw, length);
    let offset = input[0];
    if !(-146097..=146097).contains(&offset) {
        return -1;
    }
    if output.is_null() || capacity < 16 {
        return -2;
    }
    let (year, ordinal) = decode_offset(offset);
    let destination = std::slice::from_raw_parts_mut(output, 16);
    store_i64_le(destination, 0, year);
    store_i64_le(destination, 8, ordinal);
    16
}
