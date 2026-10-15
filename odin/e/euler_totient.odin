package euler_totient

// Euler's totient via distinct-prime factorization.
@(export)
euler_totient :: proc "c" (n: i64) -> i64 {
    if n < 1 || n > 1000000 do return -1
    result := n
    remaining := n
    factor := i64(2)
    for factor <= remaining / factor {
        if remaining % factor == 0 {
            for remaining % factor == 0 { remaining /= factor }
            result -= result / factor
        }
        factor += 1
    }
    if remaining > 1 do result -= result / remaining
    return result
}
