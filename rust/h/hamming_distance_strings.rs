/// Count unequal byte positions in two equal-length packed strings.
#[no_mangle]
pub unsafe extern "C" fn hamming_distance_strings(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 260 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let left_length = values[0];
    let right_length = values[1];
    if !(0..=128).contains(&left_length) || !(0..=128).contains(&right_length)
        || length != 2 + left_length as usize + right_length as usize { return -1; }
    if values[2..].iter().any(|&byte| !(0..=255).contains(&byte)) { return -1; }
    if left_length != right_length { return -1; }
    let left = &values[2..2 + left_length as usize];
    let right = &values[2 + left_length as usize..];
    left.iter().zip(right).filter(|(a, b)| a != b).count() as i64
}
