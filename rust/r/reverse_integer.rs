/// Reverse a signed 32-bit decimal integer, returning zero on overflow.
const INVALID_RESULT: i64 = -2_147_483_649;

#[no_mangle]
pub extern "C" fn reverse_integer(mut input: i64) -> i64 {
    if !(-2_147_483_648..=2_147_483_647).contains(&input) { return INVALID_RESULT; }
    let mut reversed = 0_i64;
    while input != 0 {
        let digit = input % 10;
        input /= 10;
        if reversed > 214_748_364 || (reversed == 214_748_364 && digit > 7) { return 0; }
        if reversed < -214_748_364 || (reversed == -214_748_364 && digit < -8) { return 0; }
        reversed = reversed * 10 + digit;
    }
    reversed
}
