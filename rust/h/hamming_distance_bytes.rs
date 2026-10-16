/// Count differing byte positions in two equal-length byte strings.
const MAX_BYTE_LENGTH: i64 = 1024;

#[no_mangle]
pub unsafe extern "C" fn hamming_distance_bytes(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 || length > 2050 { return -1; }
    let count_value = *values;
    if count_value < 0 || count_value > MAX_BYTE_LENGTH
        || length != 1 + 2 * count_value as usize { return -1; }

    let count = count_value as usize;
    let mut distance = 0i64;
    for index in 0..count {
        let left = *values.add(index + 1);
        let right = *values.add(count + index + 1);
        if !(0..=255).contains(&left) || !(0..=255).contains(&right) { return -1; }
        if left != right { distance += 1; }
    }
    distance
}
