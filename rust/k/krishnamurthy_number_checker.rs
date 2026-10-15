/// Check whether n equals the sum of factorials of its decimal digits.
#[no_mangle]
pub extern "C" fn krishnamurthy_number_checker(n: i64) -> i64 {
    if n < i32::MIN as i64 || n > i32::MAX as i64 {
        return -1;
    }
    if n <= 0 {
        return 0;
    }

    let original = n;
    let mut remaining = n;
    let mut sum = 0i64;
    while remaining != 0 {
        let digit = remaining % 10;
        let mut factorial = 1i64;
        for factor in 2..=digit {
            factorial *= factor;
        }
        sum += factorial;
        remaining /= 10;
    }
    (sum == original) as i64
}
