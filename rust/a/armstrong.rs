/// Check whether n is an Armstrong number in base 10.
#[no_mangle]
pub extern "C" fn armstrong(n: i64) -> i64 {
    if n < i32::MIN as i64 || n > i32::MAX as i64 {
        return -1;
    }
    if n < 0 { return 0; }
    if n == 0 { return 1; }

    let original = n;
    let mut remaining = n;
    let mut digits = 0i64;
    while remaining > 0 {
        digits += 1;
        remaining /= 10;
    }

    let mut sum = 0i64;
    remaining = n;
    while remaining > 0 {
        let digit = remaining % 10;
        let mut power = 1i64;
        for _ in 0..digits { power *= digit; }
        sum += power;
        remaining /= 10;
    }
    if sum == original { 1 } else { 0 }
}
