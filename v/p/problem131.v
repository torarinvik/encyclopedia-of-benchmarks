module problem131

const max_prime_limit = i64(1000000)

fn problem131_is_prime(number i64) bool {
    if number < 2 { return false }
    mut divisor := i64(2)
    for divisor <= number / divisor {
        if number % divisor == 0 { return false }
        divisor++
    }
    return true
}

@[export: 'problem131']
pub fn problem131(max_prime i64) i64 {
    if max_prime < 0 || max_prime > max_prime_limit { return -1 }
    mut primes_count := i64(0)
    mut cube_index := i64(1)
    mut prime_candidate := i64(7)
    for prime_candidate < max_prime {
        if problem131_is_prime(prime_candidate) { primes_count++ }
        cube_index++
        prime_candidate += 6 * cube_index
    }
    return primes_count
}
