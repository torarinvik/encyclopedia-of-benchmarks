const MAX_LIMIT: i64 = 100_000;

fn count(limit: i64) -> i64 {
    let mut prime = [true; 200_001];
    let ceiling = 2 * limit;
    prime[0] = false;
    prime[1] = false;
    let mut divisor = 2i64;
    while divisor * divisor <= ceiling {
        if prime[divisor as usize] {
            let mut multiple = divisor * divisor;
            while multiple <= ceiling {
                prime[multiple as usize] = false;
                multiple += divisor;
            }
        }
        divisor += 1;
    }

    let (mut strong, mut weak, mut balanced) = (0i64, 0i64, 0i64);
    let (mut previous, mut current) = (0i64, 0i64);
    for candidate in 2..=ceiling {
        if !prime[candidate as usize] { continue; }
        if previous != 0 && current >= 3 && current <= limit {
            let twice = 2 * current;
            let neighbors = previous + candidate;
            if twice > neighbors { strong += 1; }
            else if twice < neighbors { weak += 1; }
            else { balanced += 1; }
        }
        previous = current;
        current = candidate;
    }
    strong * 10_000_000_000 + weak * 100_000 + balanced
}

#[no_mangle]
pub unsafe extern "C" fn strong_weak_balanced_prime_distribution(
        input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let limit = values[0];
    if length != 1 || !(3..=MAX_LIMIT).contains(&limit) { return -1; }
    count(limit)
}
