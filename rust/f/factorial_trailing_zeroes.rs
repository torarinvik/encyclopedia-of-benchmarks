/// Count factors of five in n!, which determine its trailing decimal zeros.
#[no_mangle]
pub extern "C" fn factorial_trailing_zeroes(mut n: i64) -> i64 {
    if !(0..=1_000_000_000).contains(&n) { return -1; }
    let mut count = 0;
    while n > 0 {
        n /= 5;
        count += n;
    }
    count
}
