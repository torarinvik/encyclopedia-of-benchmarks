const MAX_PRIME: i64 = 100_000;

fn is_prime(value: i64) -> bool {
    if value < 2 { return false; }
    if value % 2 == 0 { return value == 2; }
    let mut divisor = 3i64;
    while divisor <= value / divisor {
        if value % divisor == 0 { return false; }
        divisor += 2;
    }
    true
}

fn class_for_prime(prime: i64, direction: i64) -> i64 {
    let mut remainder = prime + direction;
    let mut best = 1i64;
    let mut divisor = 2i64;
    while divisor <= remainder / divisor {
        if remainder % divisor == 0 {
            if divisor > 3 {
                best = best.max(1 + class_for_prime(divisor, direction));
            }
            while remainder % divisor == 0 {
                remainder /= divisor;
            }
        }
        divisor += 1;
    }
    if remainder > 3 {
        best = best.max(1 + class_for_prime(remainder, direction));
    }
    best
}

#[no_mangle]
pub unsafe extern "C" fn erdos_selfridge_prime_class(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > 3 { return -1; }
    if length != 2 { return -1; }
    let prime = unsafe { *input };
    let direction = unsafe { *input.add(1) };
    if prime < 2 || prime > MAX_PRIME || (direction != -1 && direction != 1) { return -1; }
    if !is_prime(prime) { return -1; }
    class_for_prime(prime, direction)
}

