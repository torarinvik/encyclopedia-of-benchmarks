/// Check whether n equals the sum of its positive proper divisors.
#[no_mangle]
pub extern "C" fn perfect_number(n: i64) -> i64 {
    if n <= 1 {
        return 0;
    }
    if n > 1_000_000_000_000 {
        return -1;
    }

    let number = n as u64;
    let stride = 1 + (number & 1);
    let mut divisor_sum = 1;
    if stride == 1 && number >= 4 {
        let half = number >> 1;
        divisor_sum = if half == 2 { 3 } else { 3 + half };
    }
    let mut factor = 3;
    loop {
        let partner = number / factor;
        if factor > partner { break; }
        if partner * factor == number {
            divisor_sum += factor;
            if partner != factor { divisor_sum += partner; }
            if divisor_sum > number { return 0; }
        }
        factor += stride;
    }
    (divisor_sum == number) as i64
}
