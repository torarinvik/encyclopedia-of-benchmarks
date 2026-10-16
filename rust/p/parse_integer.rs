const INVALID_RESULT: i64 = i64::MIN;

/// Parse an ASCII decimal string with Java int32 wraparound semantics.
#[no_mangle]
pub extern "C" fn parse_integer(bytes: *const i64, length: usize) -> i64 {
    if bytes.is_null() || length == 0 || length > 64 { return INVALID_RESULT; }
    let bytes = unsafe { std::slice::from_raw_parts(bytes, length) };
    if bytes.iter().any(|&byte| !(0..=127).contains(&byte)) { return INVALID_RESULT; }
    let negative = bytes[0] == 45;
    let mut index = if bytes[0] == 45 || bytes[0] == 43 { 1 } else { 0 };
    let mut number: u32 = 0;
    while index < length {
        let byte = bytes[index];
        if !(48..=57).contains(&byte) { return INVALID_RESULT; }
        number = number.wrapping_mul(10).wrapping_add((byte - 48) as u32);
        index += 1;
    }
    if negative { number = 0_u32.wrapping_sub(number); }
    (number as i32) as i64
}
