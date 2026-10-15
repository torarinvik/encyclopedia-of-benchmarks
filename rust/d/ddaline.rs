fn java_round(value: f64) -> i64 { (value + 0.5).floor() as i64 }
unsafe fn write_i64(output: *mut u8, position: &mut usize, value: i64) {
    for byte in value.to_le_bytes() { *output.add(*position) = byte; *position += 1; }
}
#[no_mangle]
pub unsafe extern "C" fn ddaline(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 4 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values.iter().any(|&v| !(-128..=128).contains(&v)) { return -1; }
    let dx = values[2] - values[0];
    let dy = values[3] - values[1];
    let steps = dx.abs().max(dy.abs());
    if steps > 256 { return -1; }
    let output_bytes = (steps as usize + 1) * 16;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut position = 0;
    if steps == 0 { write_i64(output, &mut position, values[0]); write_i64(output, &mut position, values[1]); return 16; }
    let x_inc = dx as f64 / steps as f64;
    let y_inc = dy as f64 / steps as f64;
    let mut x = values[0] as f64;
    let mut y = values[1] as f64;
    for _ in 0..=steps {
        write_i64(output, &mut position, java_round(x));
        write_i64(output, &mut position, java_round(y));
        x += x_inc;
        y += y_inc;
    }
    output_bytes as i64
}
