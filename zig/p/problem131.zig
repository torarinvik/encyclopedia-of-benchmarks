/// Count source-sequence prime candidates strictly below max_prime.
const MAX_PRIME: i64 = 1_000_000;

fn problem131IsPrime(number: i64) bool {
    if (number < 2) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(number, divisor)) : (divisor += 1) {
        if (@rem(number, divisor) == 0) return false;
    }
    return true;
}

export fn problem131(max_prime: i64) i64 {
    if (max_prime < 0 or max_prime > MAX_PRIME) return -1;
    var primes_count: i64 = 0;
    var cube_index: i64 = 1;
    var prime_candidate: i64 = 7;
    while (prime_candidate < max_prime) {
        if (problem131IsPrime(prime_candidate)) primes_count += 1;
        cube_index += 1;
        prime_candidate += 6 * cube_index;
    }
    return primes_count;
}
