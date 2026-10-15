/// Proper-divisor pair scan from the pinned Python source.
#[no_mangle]
pub extern "C" fn deficient_numbers(number: i64) -> i64 {
    if number <= 0 {
        return 0;
    }
    if number > 100_000_000 {
        return -1;
    }
    if number == 1 {
        return 1;
    }

    let mut total = 1i64;
    let mut divisor = 2i64;
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
    if total < number { 1 } else { 0 }
}
