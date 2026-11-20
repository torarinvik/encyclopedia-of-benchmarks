/// Integer-only Hough accumulator with four fixed quantized normals.
const MAX_PARSEABLE_INPUT_LENGTH: usize = 67;
const RHO_COUNT: usize = 29;
const OUTPUT_BYTES: usize = 116;

#[no_mangle]
pub unsafe extern "C" fn hough_line_transform(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let height_value = values[0];
    let width_value = values[1];
    if !(1..=8).contains(&height_value) || !(1..=8).contains(&width_value) { return -1; }
    let height = height_value as usize;
    let width = width_value as usize;
    let cells = height * width;
    if length != 2 + cells || values[2..].iter().any(|&pixel| pixel != 0 && pixel != 1) {
        return -1;
    }
    if output.is_null() || output_capacity < OUTPUT_BYTES { return -2; }

    let mut accumulator = [0u8; OUTPUT_BYTES];
    for row in 0..height {
        for column in 0..width {
            if values[2 + row * width + column] == 0 { continue; }
            let x = column as i64;
            let y = row as i64;
            let rho = [x, x + y, y, -x + y];
            for angle in 0..4 {
                let bin = angle * RHO_COUNT + (rho[angle] + 14) as usize;
                accumulator[bin] += 1;
            }
        }
    }
    std::ptr::copy_nonoverlapping(accumulator.as_ptr(), output, OUTPUT_BYTES);
    OUTPUT_BYTES as i64
}
