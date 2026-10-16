const OUTPUT_COUNT: usize = 4;

#[no_mangle]
pub unsafe extern "C" fn rgb_hsl_conversion(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, 3);
    if values.iter().any(|&value| !(0..=255).contains(&value)) { return -1; }
    if output.is_null() || capacity < OUTPUT_COUNT { return -2; }

    let red = values[0] as f64 / 255.0;
    let green = values[1] as f64 / 255.0;
    let blue = values[2] as f64 / 255.0;
    let minimum = red.min(green).min(blue);
    let maximum = red.max(green).max(blue);
    let channel = if maximum == green { 1 } else if maximum == blue { 2 } else { 0 };
    let luminance = (minimum + maximum) / 2.0;
    let mut saturation = 0.0;
    if minimum != maximum {
        saturation = if luminance <= 0.5 {
            (maximum - minimum) / (maximum + minimum)
        } else {
            (maximum - minimum) / (2.0 - maximum - minimum)
        };
    }
    let mut hue = 0.0;
    if saturation != 0.0 {
        hue = match channel {
            0 => (green - blue) / (maximum - minimum),
            1 => 2.0 + (blue - red) / (maximum - minimum),
            _ => 4.0 + (red - green) / (maximum - minimum),
        };
    }
    hue *= 60.0;
    if hue < 0.0 { hue += 360.0; }
    let h = (hue + 0.5) as u16;
    let bytes = [h as u8, (h >> 8) as u8,
        (saturation * 100.0 + 0.5) as u8, (luminance * 100.0 + 0.5) as u8];
    std::ptr::copy_nonoverlapping(bytes.as_ptr(), output, OUTPUT_COUNT);
    OUTPUT_COUNT as i64
}
