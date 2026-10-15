fn put_u64_le(output: &mut [u8], offset: usize, bits: u64) {
    output[offset..offset + 8].copy_from_slice(&bits.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn simple_moving_average(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (window_value, count_value) = (values[0], values[1]);
    if !(1..=256).contains(&window_value) || !(1..=256).contains(&count_value) { return -1; }
    let (window, count) = (window_value as usize, count_value as usize);
    if length != count + 2 { return -1; }
    let data = &values[2..];
    if data.iter().any(|value| *value < i32::MIN as i64 || *value > i32::MAX as i64) { return -1; }
    if capacity < count * 8 || output.is_null() { return -2; }
    let result = std::slice::from_raw_parts_mut(output, count * 8);
    for i in 0..count {
        if i + 1 < window {
            put_u64_le(result, i * 8, 0x7ff8_0000_0000_0000);
        } else {
            let sum: i64 = data[i + 1 - window..=i].iter().sum();
            let average = sum as f64 / window as f64;
            put_u64_le(result, i * 8, average.to_bits());
        }
    }
    (count * 8) as i64
}
