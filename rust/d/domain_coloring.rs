const MAX_OUTPUT_BYTES: usize = 768;

fn phase_hue(real_part: i64, imaginary_part: i64) -> i64 {
    if real_part == 0 && imaginary_part == 0 { return 0; }
    let abs_real = real_part.abs();
    let abs_imaginary = imaginary_part.abs();
    let high = abs_real.max(abs_imaginary);
    let low = abs_real.min(abs_imaginary);
    let step = 192 * low / high;
    let hue = if imaginary_part >= 0 {
        if real_part >= 0 {
            if abs_real >= abs_imaginary { step } else { 384 - step }
        } else if abs_real < abs_imaginary { 384 + step } else { 768 - step }
    } else if real_part < 0 {
        if abs_real >= abs_imaginary { 768 + step } else { 1152 - step }
    } else if abs_real < abs_imaginary { 1152 + step } else { 1536 - step };
    if hue == 1536 { 0 } else { hue }
}

fn store_pixel(pixels: &mut [u8; MAX_OUTPUT_BYTES], offset: usize,
               hue: i64, magnitude_16: i64) {
    let value = 128 + 8 * (magnitude_16 % 16);
    let sector = hue / 256;
    let fraction = hue % 256;
    let rising = (value * fraction / 255) as u8;
    let falling = (value * (255 - fraction) / 255) as u8;
    let bright = value as u8;
    let (red, green, blue) = match sector {
        0 => (bright, rising, 0),
        1 => (falling, bright, 0),
        2 => (0, bright, rising),
        3 => (0, falling, bright),
        4 => (rising, 0, bright),
        _ => (bright, 0, falling),
    };
    pixels[offset] = red;
    pixels[offset + 1] = green;
    pixels[offset + 2] = blue;
}

#[no_mangle]
pub unsafe extern "C" fn domain_coloring(input: *const i64, length: usize,
                                           output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 6 { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let [width_value, height_value, x_start, y_start, x_step, y_step] =
        [words[0], words[1], words[2], words[3], words[4], words[5]];
    if !(1..=16).contains(&width_value) || !(1..=16).contains(&height_value)
        || !(-32..=32).contains(&x_start) || !(-32..=32).contains(&y_start)
        || !(-8..=8).contains(&x_step) || !(-8..=8).contains(&y_step) { return -1; }
    let x_end = x_start + (width_value - 1) * x_step;
    let y_end = y_start + (height_value - 1) * y_step;
    if !(-32..=32).contains(&x_end) || !(-32..=32).contains(&y_end) { return -1; }

    let width = width_value as usize;
    let height = height_value as usize;
    let byte_count = 3 * width * height;
    let mut rendered = [0u8; MAX_OUTPUT_BYTES];
    let mut offset = 0;
    for row in 0..height {
        let y_q = y_start + row as i64 * y_step;
        for column in 0..width {
            let x_q = x_start + column as i64 * x_step;
            let x_squared = x_q * x_q;
            let y_squared = y_q * y_q;
            let hue = phase_hue(x_squared - y_squared, 2 * x_q * y_q);
            store_pixel(&mut rendered, offset, hue, x_squared + y_squared);
            offset += 3;
        }
    }
    if output.is_null() || capacity < byte_count { return -2; }
    std::ptr::copy_nonoverlapping(rendered.as_ptr(), output, byte_count);
    byte_count as i64
}
