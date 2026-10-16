const MAX_N: i64 = 10_000_000_000;

fn is_prime(value: i64, primes: &[i64]) -> bool {
    for &p in primes { if value % p == 0 { return false; } }
    true
}

#[no_mangle]
pub extern "C" fn problem111(n: i64) -> i64 {
    if !(1000..=MAX_N).contains(&n) { return -1; }
    let mut composite = [false; 100_002];
    let mut primes = [0_i64; 100_001];
    let mut prime_count = 0_usize;
    let mut root = 0_i64; while root + 1 <= n / (root + 1) { root += 1; }
    let sieve_limit = root as usize + 1;
    for p in 2..=sieve_limit {
        if composite[p] { continue; }
        primes[prime_count] = p as i64; prime_count += 1;
        if p * p <= sieve_limit { let mut multiple = p * p; while multiple <= sieve_limit { composite[multiple] = true; multiple += p; } }
    }
    let mut digits = 0; let mut copy = n; while copy > 0 { digits += 1; copy /= 10; }
    let width = digits - 1; let repeated_two = width - 2;
    let prime_slice = &primes[..prime_count];
    let mut total = 0_i64;
    for i in 1..=9 { for j in 1..=9 {
        let mut value = i as i64; for _ in 0..(width - 2) { value *= 10; } value = value * 10 + j as i64;
        if is_prime(value, prime_slice) { total += value; }
    }}
    let mut one_digit = [false; 10];
    for i in 1..=9 { for j in 0..width { for k in 0..=9 {
        let mut value = 0_i64; for pos in 0..width { value = value * 10 + if pos == j { k as i64 } else { i as i64 }; }
        if is_prime(value, prime_slice) { one_digit[i] = true; total += value; }
    }}}
    for i in 1..=9 { if !one_digit[i] {
        for j in 0..=repeated_two { for k in 0..=(repeated_two - j) { for m1 in 0..=9 {
            if m1 == 0 && j == 0 { continue; }
            for m2 in 0..=9 {
                let mut value = 0_i64;
                for pos in 0..width { let digit = if pos == j { m1 } else if pos == j + k + 1 { m2 } else { i }; value = value * 10 + digit as i64; }
                if is_prime(value, prime_slice) { total += value; }
            }
        }}}
    }}
    total
}
