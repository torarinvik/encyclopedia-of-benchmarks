package problem234

@(export)
problem234 :: proc "c" (limit: i64) -> i64 {
    if limit < 0 || limit > 999966663333 do return -1
    composite: [1_000_100]bool
    primes: [80_000]i64
    prime_count := 0
    root := i64(0)
    for (root + 1) <= limit / (root + 1) { root += 1 }
    sieve_end := int(root) + 100
    for p := 2; p < sieve_end; p += 1 {
        if composite[p] do continue
        primes[prime_count] = i64(p)
        prime_count += 1
        if p * p < sieve_end {
            for multiple := p * p; multiple < sieve_end; multiple += p { composite[multiple] = true }
        }
    }
    total := i64(0)
    index := 0
    p := primes[index]
    for p * p <= limit {
        q := primes[index + 1]
        lower := p * p
        upper := q * q
        current := lower + p
        for upper > current && current <= limit { total += current; current += p }
        for upper - q > limit { upper -= q }
        current = upper - q
        for current > lower { total += current; current -= q }
        current = 0
        for upper > current && current <= limit {
            if current <= lower { current += p * q; continue }
            if current > limit { break }
            total -= current * 2
            current += p * q
        }
        p = q
        index += 1
    }
    return total
}
