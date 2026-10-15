const MAX_U53: u64 = 9_007_199_254_740_991;
const INVALID_RESULT: i64 = -1;

#[no_mangle]
pub extern "C" fn arithmetic_left_shift(n: u64, shift: u64) -> i64 {
    if n > MAX_U53 || shift > 53 {
        return INVALID_RESULT;
    }
    ((n << (shift as u32)) & MAX_U53) as i64
}
