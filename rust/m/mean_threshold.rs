const MAX_SIDE_LENGTH: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1026;

#[no_mangle]
pub unsafe extern "C" fn mean_threshold(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] as usize > MAX_SIDE_LENGTH {
        return -1;
    }

    let side = values[0] as usize;
    let pixel_count = side * side;
    if length != pixel_count + 1 {
        return -1;
    }

    let pixels = &values[1..];
    if pixels.iter().any(|&pixel| !(0..=255).contains(&pixel)) {
        return -1;
    }
    let sum: i64 = pixels.iter().sum();
    let mean = sum / pixel_count as i64;

    if output_capacity < pixel_count || output.is_null() {
        return -2;
    }
    let result = unsafe { std::slice::from_raw_parts_mut(output, pixel_count) };
    for (destination, &pixel) in result.iter_mut().zip(pixels) {
        *destination = if pixel > mean { 255 } else { 0 };
    }
    pixel_count as i64
}

