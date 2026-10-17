/// Split printable ASCII text at the selected delimiter into a binary token record.
#[no_mangle]
pub unsafe extern "C" fn tokenize_string(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=130).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=128).contains(&values[0]) || length != 2 + values[0] as usize {
        return -1;
    }
    let text_length = values[0] as usize;
    let separator = values[1];
    if separator != 44 && separator != 46 && separator != 58 {
        return -1;
    }
    let text = &values[2..];
    let mut separator_count = 0usize;
    for &byte in text {
        if !(32..=126).contains(&byte) {
            return -1;
        }
        if byte == separator {
            separator_count += 1;
        }
    }
    if separator_count > 18 {
        return -1;
    }
    let output_length = text_length + 2;
    if output.is_null() || capacity < output_length {
        return -2;
    }
    *output = (separator_count + 1) as u8;
    for (index, &byte) in text.iter().enumerate() {
        *output.add(index + 1) = if byte == separator { 0 } else { byte as u8 };
    }
    *output.add(output_length - 1) = 0;
    output_length as i64
}
