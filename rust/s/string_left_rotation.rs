const MAX_STRING_LENGTH: usize = 256;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 259;

#[no_mangle]
pub unsafe extern "C" fn string_left_rotation(input: *const i64, length: usize,
                                                output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let raw_length = values[0];
    let raw_rotation = values[1];
    if raw_length < 0 || raw_length > MAX_STRING_LENGTH as i64 ||
        raw_rotation < 0 || raw_rotation > raw_length { return -1; }
    let text_length = raw_length as usize;
    if length != text_length + 2 { return -1; }
    let mut units = [0u16; MAX_STRING_LENGTH];
    for i in 0..text_length {
        if !(0..=65535).contains(&values[i + 2]) { return -1; }
        units[i] = values[i + 2] as u16;
    }
    let required = text_length * 2;
    if required == 0 { return 0; }
    if output.is_null() || capacity < required { return -2; }
    let rotation = raw_rotation as usize;
    let out = std::slice::from_raw_parts_mut(output, required);
    for i in 0..text_length {
        let mut source = rotation + i;
        if source >= text_length { source -= text_length; }
        let bytes = units[source].to_le_bytes();
        out[2 * i] = bytes[0];
        out[2 * i + 1] = bytes[1];
    }
    required as i64
}
