unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() { *output.add(offset + index) = *byte; }
}

#[no_mangle]
pub unsafe extern "C" fn least_recently_used(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 66 { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let capacity_value = input[0];
    let reference_count_value = input[1];
    if !(1..=16).contains(&capacity_value) || !(0..=64).contains(&reference_count_value) { return -1; }
    let cache_capacity = capacity_value as usize;
    let references = reference_count_value as usize;
    if length != 2 + references { return -1; }
    for i in 0..references {
        if input[2 + i] < i32::MIN as i64 || input[2 + i] > i32::MAX as i64 { return -1; }
    }

    let mut keys = [0i64; 16];
    let mut count = 0usize;
    for i in 0..references {
        let key = input[2 + i];
        let mut found = count;
        for j in 0..count { if keys[j] == key { found = j; break; } }
        if found < count {
            let mut j = found;
            while j + 1 < count { keys[j] = keys[j + 1]; j += 1; }
            count -= 1;
        } else if count == cache_capacity { count -= 1; }
        let mut j = count;
        while j > 0 { keys[j] = keys[j - 1]; j -= 1; }
        keys[0] = key;
        count += 1;
    }

    let elements = count + 1;
    let required = elements * 8;
    if output.is_null() || output_capacity < required { return -2; }
    put_i64_le(output, 0, count as i64);
    for i in 0..count { put_i64_le(output, 8 * (i + 1), keys[i]); }
    elements as i64
}
