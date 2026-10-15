/// Return one minus character-set Jaccard similarity for two ASCII strings.
#[no_mangle]
pub extern "C" fn jaccard_distance(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 2 { return -1.0e300; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let left_value = input[0];
    let right_value = input[1];
    if !(0..=64).contains(&left_value) || !(0..=64).contains(&right_value) { return -1.0e300; }
    let left_length = left_value as usize;
    let right_length = right_value as usize;
    if length != 2 + left_length + right_length { return -1.0e300; }
    let left = &input[2..2 + left_length];
    let right = &input[2 + left_length..];
    if left.iter().chain(right.iter()).any(|&value| !(32..=126).contains(&value)) { return -1.0e300; }

    let mut intersection = 0usize;
    let mut union_length = 0usize;
    for i in 0..left_length {
        if left[..i].contains(&left[i]) { continue; }
        union_length += 1;
        if right.contains(&left[i]) { intersection += 1; }
    }
    for j in 0..right_length {
        if right[..j].contains(&right[j]) { continue; }
        if !left.contains(&right[j]) { union_length += 1; }
    }
    if union_length == 0 { return 0.0; }
    1.0 - intersection as f64 / union_length as f64
}
