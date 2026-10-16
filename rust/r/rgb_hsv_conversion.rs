fn write_f64_le(output: &mut [u8], offset: usize, value: f64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn rgb_hsv_conversion(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, 3);
    if values.iter().any(|&x| !(0..=255).contains(&x)) { return -1; }
    if output.is_null() || capacity < 24 { return -2; }
    let out = std::slice::from_raw_parts_mut(output, 24);
    let red = values[0] as f64 / 255.0;
    let green = values[1] as f64 / 255.0;
    let blue = values[2] as f64 / 255.0;
    let value = red.max(green).max(blue);
    let chroma = value - red.min(green).min(blue);
    let saturation = if value == 0.0 { 0.0 } else { chroma / value };
    let mut hue = if chroma == 0.0 { 0.0 }
        else if value == red { 60.0 * (0.0 + (green - blue) / chroma) }
        else if value == green { 60.0 * (2.0 + (blue - red) / chroma) }
        else { 60.0 * (4.0 + (red - green) / chroma) };
    hue += 360.0;
    if hue >= 360.0 { hue -= 360.0; }
    write_f64_le(out, 0, hue);
    write_f64_le(out, 8, saturation);
    write_f64_le(out, 16, value);
    24
}
