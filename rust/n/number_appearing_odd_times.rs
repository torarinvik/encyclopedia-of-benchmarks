const MAX_LENGTH: usize = 4096;
const INVALID_RESULT: i64 = -2_147_483_649;

/// XOR-fold an int32 array to find its unique odd-frequency value.
#[no_mangle]
pub extern "C" fn number_appearing_odd_times(values: *const i64, length: usize) -> i64 {
    if length == 0 || length > MAX_LENGTH || values.is_null() { return INVALID_RESULT; }
    let mut result = 0i32;
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return INVALID_RESULT; }
        result ^= value as i32;
    }
    result as i64
}
