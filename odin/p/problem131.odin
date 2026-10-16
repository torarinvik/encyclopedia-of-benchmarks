package problem131

MAX_PRIME :: i64(1_000_000)

problem131_is_prime :: proc(number: i64) -> bool {
    if number < 2 do return false
    for divisor := i64(2); divisor <= number / divisor; divisor += 1 {
        if number % divisor == 0 do return false
    }
    return true
}

@(export)
problem131 :: proc "c" (max_prime: i64) -> i64 {
    if max_prime < 0 || max_prime > MAX_PRIME do return -1
    primes_count := i64(0)
    cube_index := i64(1)
    prime_candidate := i64(7)
    for prime_candidate < max_prime {
        if problem131_is_prime(prime_candidate) { primes_count += 1 }
        cube_index += 1
        prime_candidate += 6 * cube_index
    }
    return primes_count
}
