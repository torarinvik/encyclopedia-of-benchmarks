/// Trial-division primality check over the shared bounded integer domain.
#[no_mangle]
pub extern "C" fn prime_check(n: i64) -> i64 {
    if n < 2 {
        return 0;
    }
    if n > i32::MAX as i64 {
        return -1;
    }
    if n % 2 == 0 {
        return (n == 2) as i64;
    }
    let mut factor = 3i64;
    while factor <= n / factor {
        if n % factor == 0 {
            return 0;
        }
        factor += 2;
    }
    1
}
