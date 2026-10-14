/// Reverse half the digits to avoid overflow.
#[no_mangle]
pub extern "C" fn palindrome_number(value: i64) -> i64 {
    if !(0..=2_147_483_647).contains(&value) { return -1; }
    if value != 0 && value % 10 == 0 { return 0; }
    let mut remaining = value;
    let mut reversed_half = 0;
    while remaining > reversed_half {
        reversed_half = reversed_half * 10 + remaining % 10;
        remaining /= 10;
    }
    if remaining == reversed_half || remaining == reversed_half / 10 { 1 } else { 0 }
}
