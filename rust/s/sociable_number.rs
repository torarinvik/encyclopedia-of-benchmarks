/// Exact-cycle sociable-number check adapted from the pinned Java source.
fn sum_proper_divisors(number: u64) -> u64 {
    if number <= 1 {
        return 0;
    }
    let mut total = 1u64;
    let mut divisor = 2u64;
    while divisor <= number / divisor {
        if number % divisor == 0 {
            let other = number / divisor;
            total += divisor;
            if other != divisor {
                total += other;
            }
        }
        divisor += 1;
    }
    total
}

#[no_mangle]
pub extern "C" fn sociable_number(number: u64, cycle_length: u64) -> i64 {
    if number == 0 || number > 100_000 || !(2..=3).contains(&cycle_length) {
        return -1;
    }
    let mut current = number;
    for step in 0..cycle_length {
        current = sum_proper_divisors(current);
        if current == number {
            return if step == cycle_length - 1 { 1 } else { 0 };
        }
    }
    0
}
