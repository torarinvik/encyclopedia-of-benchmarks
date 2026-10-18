const MAX_PARSEABLE_INPUT_LENGTH: usize = 196;
const MAX_PIXELS: usize = 64;
const MAX_OUTPUT_BYTES: usize = 192;

#[no_mangle]
pub unsafe extern "C" fn sepia(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let height = values[0];
    let width = values[1];
    let factor = values[2];
    if !(1..=8).contains(&height) || !(1..=8).contains(&width) || !(0..=255).contains(&factor) { return -1; }
    let pixels = height as usize * width as usize;
    if input_length != 3 + 3 * pixels { return -1; }
    for &channel in &values[3..] {
        if channel != 0 && channel != 64 && channel != 128 && channel != 255 { return -1; }
    }

    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    for pixel in 0..pixels {
        let offset = 3 + 3 * pixel;
        let blue = values[offset] as f64;
        let green = values[offset + 1] as f64;
        let red = values[offset + 2] as f64;
        let gray = (0.2126 * red + 0.587 * green + 0.114 * blue) as i64;
        staged[3 * pixel] = gray as u8;
        staged[3 * pixel + 1] = (gray + factor).min(255) as u8;
        staged[3 * pixel + 2] = (gray + 2 * factor).min(255) as u8;
    }

    let output_bytes = 3 * pixels;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes);
    output_bytes as i64
}
