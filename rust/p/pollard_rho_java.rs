const MIN_N: i64 = 2;
const MAX_N: i64 = 46_340;
const MAX_STEPS: i64 = 4_096;

fn java_remainder(value: i64, modulus: i64) -> i64 {
    if value < 0 { -((-value) % modulus) } else { value % modulus }
}

fn next_value(value: i64, modulus: i64) -> i64 {
    java_remainder(value * value - 1, modulus)
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
pub unsafe extern "C" fn pollard_rho_java(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let n = *input;
    let step_limit = *input.add(1);
    if !(MIN_N..=MAX_N).contains(&n) || !(1..=MAX_STEPS).contains(&step_limit) { return -1; }

    let mut x = 2i64;
    let mut y = 2i64;
    for _ in 0..step_limit {
        x = next_value(x, n);
        y = next_value(next_value(y, n), n);
        let difference = (x - y).abs();
        let divisor = gcd_nonnegative(difference, n);
        if divisor == 1 { continue; }
        return if divisor == n { 0 } else { divisor };
    }
    -2
}
