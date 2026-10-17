const MAX_PARSEABLE_INPUT_LENGTH: usize = 292;
const MAX_MESSAGE_BYTES: i64 = 32;

#[no_mangle]
pub unsafe extern "C" fn lsb_image_steganography(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=16).contains(&values[0]) || !(1..=16).contains(&values[1]) || !(0..=MAX_MESSAGE_BYTES).contains(&values[2]) { return -1; }
    let rows = values[0] as usize;
    let columns = values[1] as usize;
    let message_length = values[2] as usize;
    let pixel_count = rows * columns;
    if message_length * 8 > pixel_count || length != 3 + pixel_count + message_length { return -1; }
    if values[3..3 + pixel_count].iter().any(|&pixel| !(0..=254).contains(&pixel)) { return -1; }
    if values[3 + pixel_count..].iter().any(|&byte| !(0..=127).contains(&byte)) { return -1; }
    if output.is_null() || capacity < pixel_count { return -2; }
    let result = std::slice::from_raw_parts_mut(output, pixel_count);
    for i in 0..pixel_count { result[i] = values[3 + i] as u8; }
    let mut bit_index = 0;
    for i in 0..message_length {
        let byte = values[3 + pixel_count + i] as u8;
        for shift in (0..8).rev() {
            let bit = (byte >> shift) & 1;
            let pixel = result[bit_index];
            result[bit_index] = pixel + ((pixel & 1) ^ bit);
            bit_index += 1;
        }
    }
    pixel_count as i64
}
