/// Interleave two bounded ASCII strings, then append the longer suffix.
#[no_mangle]
pub unsafe extern "C" fn alternative_string_arrange(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=64).contains(&values[0]) { return -1; }
    let first_length = values[0] as usize;
    if 1 + first_length >= length || !(0..=64).contains(&values[1 + first_length]) { return -1; }
    let second_length = values[1 + first_length] as usize;
    if length != 2 + first_length + second_length { return -1; }
    let first = &values[1..1 + first_length];
    let second = &values[2 + first_length..];
    if first.iter().chain(second.iter()).any(|&value| !(0..=127).contains(&value)) { return -1; }
    let count = first_length + second_length;
    if capacity < count || (count != 0 && output.is_null()) { return -2; }
    if count == 0 { return 0; }
    let result = std::slice::from_raw_parts_mut(output, count);
    let mut written = 0;
    for i in 0..first_length.max(second_length) {
        if i < first_length { result[written] = first[i] as u8; written += 1; }
        if i < second_length { result[written] = second[i] as u8; written += 1; }
    }
    written as i64
}
