/// Test whether the significant binary digits of an int32 value form a palindrome.
#[no_mangle]
pub extern "C" fn binary_palindrome_check(number: i64) -> i64 {
    if number < i32::MIN as i64 || number > i32::MAX as i64 { return -1; }
    if number < 0 { return 0; }
    let mut remaining = number;
    let mut reversed = 0_i64;
    while remaining > 0 {
        reversed = (reversed << 1) | (remaining & 1);
        remaining >>= 1;
    }
    if reversed == number { 1 } else { 0 }
}
