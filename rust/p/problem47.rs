fn distinct_prime_factor_count(mut value: i64) -> i64 {
    let mut count = 0;
    let mut divisor = 2;
    while divisor * divisor <= value {
        if value % divisor == 0 {
            count += 1;
            while value % divisor == 0 {
                value /= divisor;
            }
        }
        divisor += 1;
    }
    if value > 1 {
        count += 1;
    }
    count
}

#[no_mangle]
pub extern "C" fn problem47(n: i64) -> i64 {
    if !(1..=4).contains(&n) {
        return -1;
    }
    let mut value = 2;
    let mut run_length = 0;
    loop {
        if distinct_prime_factor_count(value) == n {
            run_length += 1;
        } else {
            run_length = 0;
        }
        if run_length == n {
            return value - n + 1;
        }
        value += 1;
    }
}
