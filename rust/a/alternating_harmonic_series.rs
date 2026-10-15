/// Check rationals against the canonical finite alternating harmonic terms.
const MAX_COUNT: usize = 1000;

#[no_mangle]
pub extern "C" fn alternating_harmonic_series(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 { return -1; }
    let count_value = unsafe { *values };
    if count_value < 0 || count_value > MAX_COUNT as i64 { return -1; }
    let count = count_value as usize;
    if length != 1 + 2 * count { return -1; }
    if count == 0 { return 0; }

    for index in 0..count {
        let numerator = unsafe { *values.add(1 + 2 * index) };
        let denominator = unsafe { *values.add(2 + 2 * index) };
        if !(-1000..=1000).contains(&numerator) || !(1..=1000).contains(&denominator) {
            return -1;
        }
    }

    for index in 0..count {
        let numerator = unsafe { *values.add(1 + 2 * index) };
        let denominator = unsafe { *values.add(2 + 2 * index) };
        let term_index = index as i64 + 1;
        let sign = if index % 2 == 0 { 1_i64 } else { -1_i64 };
        let error = (numerator * term_index - sign * denominator).abs();
        if error * 1_000_000_000_i64 > denominator * term_index { return 0; }
    }
    1
}
