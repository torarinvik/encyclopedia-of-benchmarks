/// Portable byte-channel brightness and contrast transforms.
fn truncate_divide(numerator: i64, denominator: i64) -> i64 {
    if numerator < 0 { -((-numerator) / denominator) } else { numerator / denominator }
}
fn transform_channel(channel: i64, level: i64, mode: i64) -> i64 {
    let value = if mode == 0 {
        channel + level
    } else {
        let denominator = 255 * (259 - level);
        let numerator = 128 * denominator + 259 * (level + 255) * (channel - 128);
        truncate_divide(numerator, denominator)
    };
    value.clamp(0, 255)
}
unsafe fn image_point_transform(values: *const i64, length: usize, output: *mut u8,
                                output_capacity: usize, mode: i64) -> i64 {
    if values.is_null() || !(1..=4096).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let level = values[0];
    if !(-255..=255).contains(&level) || values[1..].iter().any(|&pixel| !(0..=255).contains(&pixel)) {
        return -1;
    }
    let channels = length - 1;
    if channels > output_capacity || (channels != 0 && output.is_null()) { return -2; }
    if channels == 0 { return 0; }
    let result = std::slice::from_raw_parts_mut(output, channels);
    for (index, &pixel) in values[1..].iter().enumerate() {
        result[index] = transform_channel(pixel, level, mode) as u8;
    }
    channels as i64
}
#[no_mangle]
pub unsafe extern "C" fn change_brightness(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    image_point_transform(values, length, output, output_capacity, 0)
}
#[no_mangle]
pub unsafe extern "C" fn change_contrast(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    image_point_transform(values, length, output, output_capacity, 1)
}
