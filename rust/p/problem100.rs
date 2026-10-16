/// Return the blue-disc count for the first arrangement above the total threshold.
#[no_mangle]
pub extern "C" fn problem100(min_total: i64) -> i64 {
    if !(0..=1_000_000_000_000).contains(&min_total) {
        return -1;
    }
    let mut previous_numerator = 1i64;
    let mut previous_denominator = 0i64;
    let mut numerator = 1i64;
    let mut denominator = 1i64;
    while numerator <= 2 * min_total - 1 {
        previous_numerator += 2 * numerator;
        numerator += 2 * previous_numerator;
        previous_denominator += 2 * denominator;
        denominator += 2 * previous_denominator;
    }
    (denominator + 1) / 2
}
