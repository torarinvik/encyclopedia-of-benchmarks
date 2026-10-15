/// Check alternating signs and a constant step in reciprocal magnitudes.
const MAX_COUNT: usize = 1000;

#[no_mangle]
pub extern "C" fn alternate_harmonic_series(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 { return -1; }
    let count_value = unsafe { *values };
    if count_value < 1 || count_value > MAX_COUNT as i64 { return -1; }
    let count = count_value as usize;
    if length != 1 + 2 * count { return -1; }

    for index in 0..count {
        let numerator = unsafe { *values.add(1 + 2 * index) };
        let denominator = unsafe { *values.add(2 + 2 * index) };
        if !(-1000..=1000).contains(&numerator) || numerator == 0 ||
            !(1..=1000).contains(&denominator) { return -1; }
    }

    let mut previous_difference_numerator = 0_i64;
    let mut previous_difference_denominator = 1_i64;
    let mut previous_magnitude = 0_i64;
    let mut previous_denominator = 0_i64;
    let mut previous_sign = false;

    for index in 0..count {
        let numerator = unsafe { *values.add(1 + 2 * index) };
        let denominator = unsafe { *values.add(2 + 2 * index) };
        let negative = numerator < 0;
        let magnitude = if negative { -numerator } else { numerator };

        if index > 0 {
            if negative == previous_sign { return 0; }
            let difference_numerator = denominator * previous_magnitude - previous_denominator * magnitude;
            let difference_denominator = magnitude * previous_magnitude;
            if index > 1 &&
                difference_numerator * previous_difference_denominator !=
                    previous_difference_numerator * difference_denominator { return 0; }
            previous_difference_numerator = difference_numerator;
            previous_difference_denominator = difference_denominator;
        }
        previous_sign = negative;
        previous_magnitude = magnitude;
        previous_denominator = denominator;
    }
    1
}
