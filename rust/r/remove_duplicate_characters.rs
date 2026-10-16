const MAX_INPUT_LENGTH: usize = 4096;

#[no_mangle]
pub unsafe extern "C" fn remove_duplicate_characters(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH + 1 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 0 || input[0] as usize > MAX_INPUT_LENGTH || length != 1 + input[0] as usize {
        return -1;
    }
    let text = &input[1..];
    if text.iter().any(|byte| !(0..=127).contains(byte)) { return -1; }

    let mut seen = [false; 128];
    let mut output_length = 0;
    for &value in text {
        let byte = value as usize;
        if !seen[byte] { seen[byte] = true; output_length += 1; }
    }
    if output_length > output_capacity || (output_length > 0 && output.is_null()) { return -2; }

    seen.fill(false);
    let mut written = 0;
    for &value in text {
        let byte = value as usize;
        if !seen[byte] {
            seen[byte] = true;
            *output.add(written) = byte as u8;
            written += 1;
        }
    }
    written as i64
}
