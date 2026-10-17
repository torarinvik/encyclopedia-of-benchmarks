const MIN_N: i64 = 2;
const MAX_N: i64 = 111_155;

fn next_value(n: i64, x: i64) -> i64 {
    (x * x + 1) % n
}

fn gcd_nonnegative(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

#[no_mangle]
pub unsafe extern "C" fn pollard(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let n = *input;
    if !(MIN_N..=MAX_N).contains(&n) { return -1; }

    let mut x = 2i64;
    let mut y = 2i64;
    let mut divisor = 1i64;
    while divisor == 1 {
        x = next_value(n, x);
        y = next_value(n, next_value(n, y));
        divisor = gcd_nonnegative((x - y).abs(), n);
    }
    if divisor == n { 0 } else { divisor }
}
