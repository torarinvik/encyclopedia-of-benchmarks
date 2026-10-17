const MAX_INPUT_LENGTH: usize = 256;
const INT32_MAX_VALUE: i64 = 2_147_483_647;
const INT32_MIN_MAGNITUDE: i64 = 2_147_483_648;

#[no_mangle]
pub unsafe extern "C" fn my_atoi(input: *const i64, length: usize) -> i64 {
    if input.is_null() { return 0; }
    if length > MAX_INPUT_LENGTH { return i64::MIN; }
    for i in 0..length {
        let value = *input.add(i);
        if !(0..=127).contains(&value) { return i64::MIN; }
    }

    let mut start = 0;
    let mut end = length;
    while start < end && *input.add(start) <= 32 { start += 1; }
    while end > start && *input.add(end - 1) <= 32 { end -= 1; }
    if start == end { return 0; }

    let mut negative = false;
    let first = *input.add(start);
    if first == 43 || first == 45 {
        negative = first == 45;
        start += 1;
    }
    let limit = if negative { INT32_MIN_MAGNITUDE } else { INT32_MAX_VALUE };
    let mut magnitude = 0_i64;
    while start < end {
        let value = *input.add(start);
        if !(48..=57).contains(&value) { break; }
        let digit = value - 48;
        if magnitude > limit / 10 || (magnitude == limit / 10 && digit > limit % 10) {
            return if negative { -INT32_MIN_MAGNITUDE } else { INT32_MAX_VALUE };
        }
        magnitude = magnitude * 10 + digit;
        start += 1;
    }
    if negative { -magnitude } else { magnitude }
}
