/// Exact decimal digit powers; 1 for Armstrong numbers and 0 otherwise.
#[no_mangle]
pub extern "C" fn armstrong_number(n: i64) -> i64 {
    if n < 0 { return 0; }
    if n == 0 { return 1; }
    let mut digits = 0i64;
    let mut remaining = n;
    while remaining > 0 {
        digits += 1;
        remaining /= 10;
    }
    let mut sum = 0i64;
    remaining = n;
    while remaining > 0 {
        let digit = remaining % 10;
        let mut power = 1i64;
        let mut exponent = 0i64;
        while exponent < digits {
            power *= digit;
            exponent += 1;
        }
        if power > n - sum { return 0; }
        sum += power;
        remaining /= 10;
    }
    if sum == n { 1 } else { 0 }
}
