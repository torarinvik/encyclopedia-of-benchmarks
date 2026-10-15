/// Return intersection-over-union similarity for two unique ASCII sets.
#[no_mangle]
pub extern "C" fn jaccard_similarity(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 2 { return -1.0e300; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let left_length = input[0];
    let right_length = input[1];
    if !(0..=64).contains(&left_length) || !(0..=64).contains(&right_length)
        || (left_length == 0 && right_length == 0) { return -1.0e300; }
    let left_length = left_length as usize;
    let right_length = right_length as usize;
    if length != 2 + left_length + right_length { return -1.0e300; }
    let left = &input[2..2 + left_length];
    let right = &input[2 + left_length..];
    for (values, _) in [(left, left_length), (right, right_length)] {
        if values.iter().any(|&value| !(32..=126).contains(&value)) { return -1.0e300; }
        for i in 0..values.len() {
            if values[..i].contains(&values[i]) { return -1.0e300; }
        }
    }
    let intersection = left.iter().filter(|value| right.contains(value)).count();
    let union_length = left_length + right_length - intersection;
    intersection as f64 / union_length as f64
}
