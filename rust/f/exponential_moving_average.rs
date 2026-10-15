fn put_f64_le(output: &mut [u8], offset: usize, value: f64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn exponential_moving_average(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (window_value, count_value) = (values[0], values[1]);
    if !(2..=32).contains(&window_value) || !(1..=256).contains(&count_value) { return -1; }
    let (window, count) = (window_value as usize, count_value as usize);
    if length != count + 2 { return -1; }
    let prices = &values[2..];
    if prices.iter().any(|price| !(-1_000_000..=1_000_000).contains(price)) { return -1; }
    if output.is_null() || capacity < count * 8 { return -2; }
    let result = std::slice::from_raw_parts_mut(output, count * 8);
    let alpha = 2.0 / (1.0 + window as f64);
    let mut average = 0.0_f64;
    for (i, price) in prices.iter().enumerate() {
        let price = *price as f64;
        average = if i == 0 { price }
        else if i <= window { (average + price) * 0.5 }
        else { (alpha * price) + ((1.0 - alpha) * average) };
        put_f64_le(result, i * 8, average);
    }
    (count * 8) as i64
}
