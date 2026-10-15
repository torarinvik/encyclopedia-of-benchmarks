fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        output[offset + byte] = ((bits >> (byte * 8)) & 0xff) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn auto_correlation(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || !(2..=65).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let raw_count = input[0];
    if !(1..=64).contains(&raw_count) { return -1; }
    let count = raw_count as usize;
    if length != count + 1 || input[1..].iter().any(|&sample| !(-1_000_000..=1_000_000).contains(&sample)) { return -1; }
    let result_count = 2 * count - 1;
    let byte_count = 8 * result_count;
    if output.is_null() || capacity < byte_count { return -2; }
    let result = std::slice::from_raw_parts_mut(output, capacity);

    let mut y_start = count;
    for index in 0..result_count {
        if index < count { y_start -= 1; }
        let k_min = if index >= count - 1 { index - (count - 1) } else { 0 };
        let k_max = if index < count { index } else { count - 1 };
        let mut offset = 0;
        let mut sum = 0i64;
        for k in k_min..=k_max {
            sum += input[k + 1] * input[y_start + offset + 1];
            offset += 1;
        }
        store_i64_le(result, index * 8, sum);
    }
    byte_count as i64
}
