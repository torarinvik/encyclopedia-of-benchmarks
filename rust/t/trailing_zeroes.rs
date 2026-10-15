/// Count decimal zero digits at the end of a nonnegative integer.
#[no_mangle]
pub extern "C" fn trailing_zeroes(mut n: i64) -> i64 {
    if n < 0 { return -1; }
    if n == 0 { return 1; }
    let mut count = 0;
    while n % 10 == 0 {
        count += 1;
        n /= 10;
    }
    count
}
