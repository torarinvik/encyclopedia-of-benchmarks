const INVALID_RESULT: f64 = -1.0e300;

fn component(channel: i64) -> f64 {
    let srgb = channel as f64 / 255.0;
    if srgb <= 0.03928 { return srgb / 12.92; }
    ((srgb + 0.055) / 1.055).powf(2.4)
}

fn luminance(red: i64, green: i64, blue: i64) -> f64 {
    0.2126 * component(red) + 0.7152 * component(green) + 0.0722 * component(blue)
}

#[no_mangle]
pub extern "C" fn color_contrast_ratio(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 6 { return INVALID_RESULT; }
    let channels = unsafe { std::slice::from_raw_parts(values, 6) };
    if channels.iter().any(|&channel| !(0..=255).contains(&channel)) { return INVALID_RESULT; }
    let first = luminance(channels[0], channels[1], channels[2]);
    let second = luminance(channels[3], channels[4], channels[5]);
    if first > second { return (first + 0.05) / (second + 0.05); }
    (second + 0.05) / (first + 0.05)
}
