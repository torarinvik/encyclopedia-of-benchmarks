/// XOR a consecutive signed 32-bit range using portable zero-extended bit patterns.
const MAX_VALUES: usize = 1024;
const INVALID_RESULT: i64 = -2_147_483_649;

fn encode_i32(value: i64) -> u64 {
    if value < 0 { (value + 4_294_967_296) as u64 } else { value as u64 }
}

#[no_mangle]
pub extern "C" fn missing_number_in_range(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_VALUES { return INVALID_RESULT; }
    let mut low = unsafe { *values };
    let mut high = low;
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if !(-2_147_483_648..=2_147_483_647).contains(&value) { return INVALID_RESULT; }
        low = low.min(value);
        high = high.max(value);
    }
    if high - low != length as i64 { return INVALID_RESULT; }
    let mut seen = [false; MAX_VALUES + 1];
    let mut actual = 0u64;
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        let slot = (value - low) as usize;
        if seen[slot] { return INVALID_RESULT; }
        seen[slot] = true;
        actual ^= encode_i32(value);
    }
    let mut expected = 0u64;
    let mut value = low;
    while value <= high {
        expected ^= encode_i32(value);
        value += 1;
    }
    let result = expected ^ actual;
    if result <= 2_147_483_647 { result as i64 } else { result as i64 - 4_294_967_296 }
}
