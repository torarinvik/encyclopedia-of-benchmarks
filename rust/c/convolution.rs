fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn convolution(values: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || !(4..=130).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let (raw_a_count, raw_b_count) = (input[0], input[1]);
    if !(1..=64).contains(&raw_a_count) || !(1..=64).contains(&raw_b_count) { return -1; }
    let (a_count, b_count) = (raw_a_count as usize, raw_b_count as usize);
    if length != a_count + b_count + 2 || input[2..].iter().any(|&x| !(-1_000_000..=1_000_000).contains(&x)) { return -1; }
    let result_count = a_count + b_count - 1;
    let byte_count = result_count * 8;
    if output.is_null() || capacity < byte_count { return -2; }
    let result = std::slice::from_raw_parts_mut(output, byte_count);
    for i in 0..result_count {
        let k_start = if i >= b_count - 1 { i - (b_count - 1) } else { 0 };
        let k_end = if i < a_count { i } else { a_count - 1 };
        let mut sum = 0i64;
        for k in k_start..=k_end { sum += input[k + 2] * input[a_count + (i - k) + 2]; }
        store_i64_le(result, i * 8, sum);
    }
    byte_count as i64
}
