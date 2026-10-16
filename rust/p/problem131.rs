/// Count source-sequence prime candidates strictly below max_prime.
const MAX_PRIME: i64 = 1_000_000;

fn problem131_is_prime(number: i64) -> bool {
    if number < 2 {
        return false;
    }
    let mut divisor = 2i64;
    while divisor <= number / divisor {
        if number % divisor == 0 {
            return false;
        }
        divisor += 1;
    }
    true
}

#[no_mangle]
pub extern "C" fn problem131(max_prime: i64) -> i64 {
    if max_prime < 0 || max_prime > MAX_PRIME {
        return -1;
    }
    let mut primes_count = 0i64;
    let mut cube_index = 1i64;
    let mut prime_candidate = 7i64;
    while prime_candidate < max_prime {
        primes_count += problem131_is_prime(prime_candidate) as i64;
        cube_index += 1;
        prime_candidate += 6 * cube_index;
    }
    primes_count
}
