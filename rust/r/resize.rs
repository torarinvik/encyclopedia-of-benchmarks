const MAX_INPUT_LENGTH: usize = 3077;
const MAX_OUTPUT_BYTES: usize = 3072;

#[no_mangle]
pub unsafe extern "C" fn resize(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let (src_width, src_height, dst_width, dst_height) =
        (values[0], values[1], values[2], values[3]);
    if !(1..=32).contains(&src_width)
        || !(1..=32).contains(&src_height)
        || !(1..=32).contains(&dst_width)
        || !(1..=32).contains(&dst_height)
    {
        return -1;
    }

    let expected_length = 4 + 3 * src_width as usize * src_height as usize;
    if length != expected_length || values[4..].iter().any(|&channel| !(0..=255).contains(&channel)) {
        return -1;
    }

    let needed = 3 * dst_width as usize * dst_height as usize;
    if needed > MAX_OUTPUT_BYTES {
        return -1;
    }
    if output.is_null() || capacity < needed {
        return -2;
    }

    let result = std::slice::from_raw_parts_mut(output, needed);
    let ratio_x = src_width as f64 / dst_width as f64;
    let ratio_y = src_height as f64 / dst_height as f64;
    let mut out = 0;
    for y in 0..dst_height as usize {
        let src_y = (ratio_y * y as f64) as usize;
        for x in 0..dst_width as usize {
            let src_x = (ratio_x * x as f64) as usize;
            let src = 4 + 3 * (src_y * src_width as usize + src_x);
            result[out] = values[src] as u8;
            result[out + 1] = values[src + 1] as u8;
            result[out + 2] = values[src + 2] as u8;
            out += 3;
        }
    }
    needed as i64
}
