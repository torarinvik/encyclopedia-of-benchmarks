package sum_of_divisors

// Return the sum of all positive divisors of n by prime factorization.
@(export)
sum_of_divisors :: proc "c" (n: i64) -> i64 {
    if n < 1 || n > 1000000 do return -1
    remaining := n
    sigma := i64(1)
    factor := i64(2)
    for factor <= remaining / factor {
        if remaining % factor == 0 {
            power := i64(1)
            geometric_sum := i64(1)
            for remaining % factor == 0 {
                remaining /= factor
                power *= factor
                geometric_sum += power
            }
            sigma *= geometric_sum
        }
        factor += 1
    }
    if remaining > 1 do sigma *= remaining + 1
    return sigma
}
