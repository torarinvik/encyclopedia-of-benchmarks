/// Multiply two bounded signed operands; the bounds guarantee an i64 result.
const INVALID_RESULT: i64 = i64::MIN;

#[no_mangle]
pub extern "C" fn multiply_digit(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let first = unsafe { *values };
    let second = unsafe { *values.add(1) };
    if !(-1_000_000_000..=1_000_000_000).contains(&first) ||
        !(-1_000_000_000..=1_000_000_000).contains(&second) {
        return INVALID_RESULT;
    }
    first * second
}
