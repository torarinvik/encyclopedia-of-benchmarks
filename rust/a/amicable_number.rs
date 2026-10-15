fn proper_divisor_sum(number: u64) -> u64 {
    if number <= 1 { return 0; }
    let mut sum = 1u64;
    let mut divisor = 2u64;
    while divisor <= number / divisor {
        if number % divisor == 0 {
            sum += divisor;
            let partner = number / divisor;
            if partner != divisor { sum += partner; }
        }
        divisor += 1;
    }
    sum
}

#[no_mangle]
pub extern "C" fn amicable_number(left: u64, right: u64) -> i64 {
    if left < 1 || left > 1_000_000_000 || right < 1 || right > 1_000_000_000 { return -1; }
    if left == right { return 0; }
    i64::from(proper_divisor_sum(left) == right && proper_divisor_sum(right) == left)
}
