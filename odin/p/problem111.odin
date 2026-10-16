package problem111

max_n :: i64(10_000_000_000)

is_prime :: proc(value: i64, primes: []i64) -> bool {
    for p in primes { if value % p == 0 do return false }
    return true
}

@(export)
problem111 :: proc "c" (n: i64) -> i64 {
    if n < 1000 || n > max_n do return -1
    composite: [100_002]bool
    primes: [100_001]i64
    prime_count := 0
    root := i64(0)
    for root + 1 <= n / (root + 1) { root += 1 }
    sieve_limit := int(root) + 1
    for p := 2; p <= sieve_limit; p += 1 {
        if composite[p] do continue
        primes[prime_count] = i64(p)
        prime_count += 1
        if p * p <= sieve_limit { for multiple := p * p; multiple <= sieve_limit; multiple += p { composite[multiple] = true } }
    }
    digits := 0
    for copy := n; copy > 0; copy /= 10 { digits += 1 }
    width := digits - 1
    repeated_two := width - 2
    total := i64(0)
    prime_slice := primes[:prime_count]
    for i := 1; i <= 9; i += 1 {
        for j := 1; j <= 9; j += 1 {
            value := i64(i)
            for z := 0; z < width - 2; z += 1 { value *= 10 }
            value = value * 10 + i64(j)
            if is_prime(value, prime_slice) { total += value }
        }
    }
    one_digit: [10]bool
    for i := 1; i <= 9; i += 1 {
        for j := 0; j < width; j += 1 {
            for k := 0; k <= 9; k += 1 {
                value := i64(0)
                for pos := 0; pos < width; pos += 1 { value = value * 10 + i64(if pos == j { k } else { i }) }
                if is_prime(value, prime_slice) { one_digit[i] = true; total += value }
            }
        }
    }
    for i := 1; i <= 9; i += 1 {
        if one_digit[i] do continue
        for j := 0; j <= repeated_two; j += 1 {
            for k := 0; k <= repeated_two - j; k += 1 {
                for m1 := 0; m1 <= 9; m1 += 1 {
                    if m1 == 0 && j == 0 do continue
                    for m2 := 0; m2 <= 9; m2 += 1 {
                        value := i64(0)
                        for pos := 0; pos < width; pos += 1 {
                            digit := i
                            if pos == j { digit = m1 } else if pos == j + k + 1 { digit = m2 }
                            value = value * 10 + i64(digit)
                        }
                        if is_prime(value, prime_slice) { total += value }
                    }
                }
            }
        }
    }
    return total
}
