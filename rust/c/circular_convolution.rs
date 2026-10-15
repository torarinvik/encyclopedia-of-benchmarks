#[no_mangle]
pub unsafe extern "C" fn circular_convolution(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 4 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let raw_a_length = input[0];
    let raw_b_length = input[1];
    if !(1..=8).contains(&raw_a_length) || !(1..=8).contains(&raw_b_length) { return -1; }
    let a_length = raw_a_length as usize;
    let b_length = raw_b_length as usize;
    if length != 2 + a_length + b_length { return -1; }
    if input[2..].iter().any(|&sample| !(-2..=2).contains(&sample)) { return -1; }
    let n = a_length.max(b_length);
    if output.is_null() || capacity < n { return -2; }
    let result = std::slice::from_raw_parts_mut(output, capacity);

    for k in 0..n {
        let mut sum = 0i64;
        for i in 0..n {
            let b_index = (k + n - i) % n;
            let a_value = if i < a_length { input[2 + i] } else { 0 };
            let b_value = if b_index < b_length { input[2 + a_length + b_index] } else { 0 };
            sum += a_value * b_value;
        }
        result[k] = if sum < 0 { (sum + 256) as u8 } else { sum as u8 };
    }
    n as i64
}
