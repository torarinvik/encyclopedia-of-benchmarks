/// Incremental floating-point DDA points, each encoded as an i32 little-endian pair.
fn round_ties_to_even(value: f64) -> i64 {
    let lower = value.floor() as i64;
    let fraction = value - lower as f64;
    if fraction > 0.5 || (fraction == 0.5 && lower % 2 != 0) { lower + 1 } else { lower }
}

unsafe fn write_i32_le(output: *mut u8, position: &mut usize, value: i64) {
    let bytes = (value as i32).to_le_bytes();
    for byte in bytes { *output.add(*position) = byte; *position += 1; }
}

#[no_mangle]
pub unsafe extern "C" fn digital_differential_analyzer_line(values: *const i64, length: usize,
                                                               output: *mut u8, output_capacity: usize) -> i64 {
    if length != 4 { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    if values.iter().any(|&value| !(-1_000_000..=1_000_000).contains(&value)) { return -1; }
    let dx = values[2] - values[0];
    let dy = values[3] - values[1];
    let steps = dx.abs().max(dy.abs());
    if steps == 0 || steps > 4096 { return -1; }
    let output_bytes = steps as usize * 8;
    if output_capacity < output_bytes || output.is_null() { return -2; }
    let x_increment = dx as f64 / steps as f64;
    let y_increment = dy as f64 / steps as f64;
    let mut x = values[0] as f64;
    let mut y = values[1] as f64;
    let mut position = 0;
    for _ in 0..steps {
        x += x_increment;
        y += y_increment;
        write_i32_le(output, &mut position, round_ties_to_even(x));
        write_i32_le(output, &mut position, round_ties_to_even(y));
    }
    output_bytes as i64
}
