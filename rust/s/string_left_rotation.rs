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
    if text_length == 0 { return 0; }
    let mut units = [0u16; MAX_STRING_LENGTH];
    let mut observed_bits = 0u64;
    for (unit, &value) in units.iter_mut().zip(&values[2..]) {
        observed_bits |= value as u64;
        *unit = value as u16;
    }
    if observed_bits > 65535 { return -1; }
    let required = text_length * 2;
    if output.is_null() || capacity < required { return -2; }
    let rotation = raw_rotation as usize;
    let out = std::slice::from_raw_parts_mut(output, required);
    let (prefix, suffix) = units[..text_length].split_at(rotation);
    let (front, back) = out.split_at_mut(2 * suffix.len());
    for (unit, bytes) in suffix.iter().zip(front.chunks_exact_mut(2)) {
        bytes.copy_from_slice(&unit.to_le_bytes());
    }
    for (unit, bytes) in prefix.iter().zip(back.chunks_exact_mut(2)) {
        bytes.copy_from_slice(&unit.to_le_bytes());
    }
    required as i64
}
