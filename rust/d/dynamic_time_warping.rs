const MAX_SERIES_LENGTH: i64 = 16;
const MAX_SAMPLE_VALUE: i64 = 1_000;
const INVALID_RESULT: f64 = -1.0e300;
const UNREACHABLE: f64 = 1.0e300;

#[no_mangle]
pub extern "C" fn dynamic_time_warping(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 3 || length > 35 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let first_length_value = input[0];
    let second_length_value = input[1];
    let band_value = input[2];
    if !(1..=MAX_SERIES_LENGTH).contains(&first_length_value) ||
        !(1..=MAX_SERIES_LENGTH).contains(&second_length_value) { return INVALID_RESULT; }
    let first_length = first_length_value as usize;
    let second_length = second_length_value as usize;
    if band_value < (first_length_value - second_length_value).abs() ||
        band_value > MAX_SERIES_LENGTH || length != 3 + first_length + second_length { return INVALID_RESULT; }
    let band = band_value as usize;
    if input[3..].iter().any(|&value| !(-MAX_SAMPLE_VALUE..=MAX_SAMPLE_VALUE).contains(&value)) {
        return INVALID_RESULT;
    }

    let mut rows = [[UNREACHABLE; 17]; 2];
    for column in 0..=second_length { rows[0][column] = UNREACHABLE; }
    rows[0][0] = 0.0;
    for row in 1..=first_length {
        let current = row % 2;
        let previous = (row - 1) % 2;
        for column in 0..=second_length { rows[current][column] = UNREACHABLE; }
        let start = if row > band { row - band } else { 1 };
        let end = (row + band).min(second_length);
        for column in start..=end {
            let difference = (input[3 + row - 1] - input[3 + first_length + column - 1]).abs();
            let mut best = rows[previous][column];
            if rows[current][column - 1] < best { best = rows[current][column - 1]; }
            if rows[previous][column - 1] < best { best = rows[previous][column - 1]; }
            rows[current][column] = difference as f64 + best;
        }
    }
    rows[first_length % 2][second_length]
}
