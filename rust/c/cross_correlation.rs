fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn cross_correlation(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || !(4..=66).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let raw_x_count = input[0];
    let raw_y_count = input[1];
    if !(1..=32).contains(&raw_x_count) || !(1..=32).contains(&raw_y_count) { return -1; }
    let x_count = raw_x_count as usize;
    let y_count = raw_y_count as usize;
    if length != x_count + y_count + 2 { return -1; }
    if input[2..].iter().any(|&sample| !(-1_000_000..=1_000_000).contains(&sample)) { return -1; }
    let result_count = x_count + y_count - 1;
    let byte_count = 8 * result_count;
    if output.is_null() || capacity < byte_count { return -2; }
    let result = std::slice::from_raw_parts_mut(output, capacity);

    let mut y_start = y_count;
    for index in 0..result_count {
        if index < y_count { y_start -= 1; }
        let k_min = if index >= y_count - 1 { index - (y_count - 1) } else { 0 };
        let k_max = if index < x_count { index } else { x_count - 1 };
        let mut sum = 0i64;
        for k in k_min..=k_max {
            let y_index = y_start + (k - k_min);
            sum += input[k + 2] * input[x_count + y_index + 2];
        }
        store_i64_le(result, index * 8, sum);
    }
    byte_count as i64
}
