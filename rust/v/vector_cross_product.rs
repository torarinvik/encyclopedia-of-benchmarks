/// Cross two bounded integer vectors and encode components plus magnitude.
#[no_mangle]
pub extern "C" fn vector_cross_product(input: *const i64, input_length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || input_length != 6 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, 6) };
    if values.iter().any(|&value| !(-1_000_000..=1_000_000).contains(&value)) { return -1; }
    let x = values[1] * values[5] - values[2] * values[4];
    let y = -((values[0] * values[5]) - (values[2] * values[3]));
    let z = values[0] * values[4] - values[1] * values[3];
    let magnitude = ((x as f64) * (x as f64) + (y as f64) * (y as f64) + (z as f64) * (z as f64)).sqrt();
    let magnitude_micro = (magnitude * 1_000_000.0 + 0.5) as i64;
    if output.is_null() || output_capacity < 32 { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output, 32) };
    for (index, value) in [x, y, z, magnitude_micro].iter().enumerate() {
        output[index * 8..index * 8 + 8].copy_from_slice(&value.to_le_bytes());
    }
    32
}
