const MAX_DENOMINATOR: i64 = 12_000;

fn gcd(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

#[no_mangle]
pub extern "C" fn problem73(max_denominator: i64) -> i64 {
    if max_denominator < 0 || max_denominator > MAX_DENOMINATOR { return -1; }
    let mut count = 0i64;
    for denominator in 0..=max_denominator {
        let mut numerator_start = denominator / 3 + 1;
        let mut numerator_step = 1;
        if denominator % 2 == 0 {
            numerator_start += 1 - numerator_start % 2;
            numerator_step = 2;
        }
        let numerator_end = (denominator + 1) / 2;
        let mut numerator = numerator_start;
        while numerator < numerator_end {
            if gcd(numerator, denominator) == 1 { count += 1; }
            numerator += numerator_step;
        }
    }
    count
}
