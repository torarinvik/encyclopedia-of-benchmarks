#[no_mangle]
pub unsafe extern "C" fn piecewise_linear_transform(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=256).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if values.iter().any(|&pixel| !(0..=255).contains(&pixel)) {
        return -1;
    }
    if output.is_null() || capacity < length {
        return -2;
    }
    let bytes = std::slice::from_raw_parts_mut(output, length);
    for (destination, &value) in bytes.iter_mut().zip(values) {
        let pixel = value as f64;
        let mapped = if pixel <= 100.0 {
            (50.0 / 100.0) * pixel
        } else if pixel <= 180.0 {
            ((200.0 - 50.0) / (180.0 - 100.0)) * (pixel - 100.0) + 50.0
        } else {
            ((255.0 - 200.0) / (255.0 - 180.0)) * (pixel - 180.0) + 200.0
        };
        *destination = mapped as u8;
    }
    length as i64
}
