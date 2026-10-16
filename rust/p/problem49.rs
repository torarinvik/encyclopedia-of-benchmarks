fn digit_signature(value: i64) -> usize {
    let mut digits = [value / 1000, value / 100 % 10, value / 10 % 10, value % 10];
    for first in 0..4 {
        for second in first + 1..4 {
            if digits[first] > digits[second] {
                digits.swap(first, second);
            }
        }
    }
    (digits[0] * 1000 + digits[1] * 100 + digits[2] * 10 + digits[3]) as usize
}

#[no_mangle]
pub extern "C" fn problem49(ignored: i64) -> i64 {
    if ignored != 0 { return -1; }
    let mut prime_flags = [false; 10_000];
    prime_flags[2..].fill(true);
    for prime in 2..100 {
        if !prime_flags[prime] { continue; }
        for multiple in (prime * prime..10_000).step_by(prime) { prime_flags[multiple] = false; }
    }
    let mut primes = [0i64; 1100];
    let mut signatures = [0usize; 10_000];
    let mut prime_count = 0usize;
    for value in (1001..10_000).step_by(2) {
        if prime_flags[value] {
            primes[prime_count] = value as i64;
            prime_count += 1;
            signatures[value] = digit_signature(value as i64);
        }
    }
    let mut seen_signatures = [false; 10_000];
    let mut best = 0i64;
    for seed in 0..prime_count {
        let signature = signatures[primes[seed] as usize];
        if seen_signatures[signature] { continue; }
        seen_signatures[signature] = true;
        let mut group = [0i64; 24];
        let mut group_count = 0usize;
        for candidate in 0..prime_count {
            let value = primes[candidate];
            if signatures[value as usize] == signature {
                group[group_count] = value;
                group_count += 1;
            }
        }
        let mut found = false;
        for first in 0..group_count {
            if found { break; }
            for second in first + 1..group_count {
                if found { break; }
                for third in second + 1..group_count {
                    if group[second] - group[first] == group[third] - group[second] {
                        let sequence = group[first] * 100_000_000 + group[second] * 10_000 + group[third];
                        if sequence > best { best = sequence; }
                        found = true;
                        break;
                    }
                }
            }
        }
    }
    best
}
