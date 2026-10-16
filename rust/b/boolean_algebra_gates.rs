const MAX_INPUT_COUNT: usize = 4096;
const INVALID_RESULT: i64 = -1;

#[no_mangle]
pub extern "C" fn boolean_algebra_gates(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_COUNT + 2 {
        return INVALID_RESULT;
    }
    let gate = unsafe { *values };
    let count = unsafe { *values.add(1) };
    if gate < 0 || gate > 5 || count < 0 || count > MAX_INPUT_COUNT as i64 {
        return INVALID_RESULT;
    }
    if count as usize != length - 2 {
        return INVALID_RESULT;
    }
    if gate == 2 && count != 1 {
        return INVALID_RESULT;
    }
    let mut result = if gate == 0 || gate == 4 { 1 } else { 0 };
    for index in 0..count as usize {
        let bit = unsafe { *values.add(index + 2) };
        if bit != 0 && bit != 1 {
            return INVALID_RESULT;
        }
        if gate == 0 || gate == 4 { result &= bit; }
        else if gate == 1 || gate == 5 { result |= bit; }
        else if gate == 2 { result = 1 - bit; }
        else { result ^= bit; }
    }
    if gate == 4 || gate == 5 { result = 1 - result; }
    result
}
