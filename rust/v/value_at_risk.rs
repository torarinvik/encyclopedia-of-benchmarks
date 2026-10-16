const SCALE: i64 = 1_000_000;
const MAX_RETURNS: usize = 64;
const MAX_PARSED_RETURNS: i64 = 65;
const MAX_SAMPLE: i64 = 1_000_000_000;
const MAX_INPUT_LENGTH: usize = 67;
const INVALID_RESULT: f64 = -1.0e300;

fn sift_down(values: &mut [f64], root_start: usize, end: usize) {
    let mut root = root_start;
    while root < end / 2 {
        let mut child = root * 2 + 1;
        if child + 1 < end && values[child] < values[child + 1] { child += 1; }
        if values[root] >= values[child] { break; }
        values.swap(root, child);
        root = child;
    }
}

fn heap_sort(values: &mut [f64]) {
    let length = values.len();
    for start in (0..length / 2).rev() { sift_down(values, start, length); }
    for end in (2..=length).rev() { values.swap(0, end - 1); sift_down(values, 0, end - 1); }
}

#[no_mangle]
pub unsafe extern "C" fn value_at_risk(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let confidence_micro = *input;
    let count_value = *input.add(1);
    if confidence_micro < 1 || confidence_micro >= SCALE || count_value < 1 || count_value > MAX_PARSED_RETURNS { return INVALID_RESULT; }
    if length != 2 + count_value as usize || count_value > MAX_RETURNS as i64 { return INVALID_RESULT; }
    let count = count_value as usize;
    let mut returns = [0.0_f64; MAX_RETURNS];
    for index in 0..count {
        let value = *input.add(2 + index);
        if value < -MAX_SAMPLE || value > MAX_SAMPLE { return INVALID_RESULT; }
        returns[index] = value as f64 / SCALE as f64;
    }
    heap_sort(&mut returns[..count]);
    let confidence = confidence_micro as f64 / SCALE as f64;
    let quantile = 1.0 - confidence;
    let position = (count - 1) as f64 * quantile;
    let lower = position as usize;
    let fraction = position - lower as f64;
    let threshold = if lower == count - 1 { returns[count - 1] }
        else { returns[lower] * (1.0 - fraction) + returns[lower + 1] * fraction };
    return -threshold;
}
