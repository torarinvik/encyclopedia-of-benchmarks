module euler_totient

// Euler's totient via distinct-prime factorization.
@[export: 'euler_totient']
pub fn euler_totient(n i64) i64 {
    if n < 1 || n > 1000000 { return -1 }
    mut result := n
    mut remaining := n
    mut factor := i64(2)
    for factor <= remaining / factor {
        if remaining % factor == 0 {
            for remaining % factor == 0 { remaining /= factor }
            result -= result / factor
        }
        factor++
    }
    if remaining > 1 { result -= result / remaining }
    return result
}
