/// Parse an ASCII byte sequence like C atoi, clamping to signed 32-bit bounds.
const MAX_INPUT_LENGTH: usize = 4096;
const INT32_MAX_VALUE: i64 = 2147483647;
const INT32_MIN_MAGNITUDE: i64 = 2147483648;

#[no_mangle]
pub unsafe extern "C" fn string_to_integer(input: *const i64, length: usize) -> i64 {
    if length > MAX_INPUT_LENGTH || (length != 0 && input.is_null()) { return -2; }
    for position in 0..length {
        let value = *input.add(position);
        if !(1..=127).contains(&value) { return -2; }
    }
    let mut index = 0;
    while index < length && *input.add(index) == 32 { index += 1; }
    let mut negative = false;
    if index < length && (*input.add(index) == 43 || *input.add(index) == 45) {
        negative = *input.add(index) == 45;
        index += 1;
    }
    let limit = if negative { INT32_MIN_MAGNITUDE } else { INT32_MAX_VALUE };
    let mut magnitude = 0i64;
    while index < length {
        let value = *input.add(index);
        if !(48..=57).contains(&value) { break; }
        let digit = value - 48;
        if magnitude > limit / 10 || (magnitude == limit / 10 && digit > limit % 10) {
            return if negative { -INT32_MIN_MAGNITUDE } else { INT32_MAX_VALUE };
        }
        magnitude = magnitude * 10 + digit;
        index += 1;
    }
    if negative { -magnitude } else { magnitude }
}
