const max_n = i64(1_000_005)

@[export: 'smallest_prime_factor']
pub fn smallest_prime_factor(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length != 1 { return -1 }
        n := input[0]
        if n < 2 || n > max_n { return -1 }
        mut factor := i64(2)
        for factor <= n / factor {
            if n % factor == 0 { return factor }
            factor++
        }
        return n
    }
}
