const MAX_LIMIT: i64 = 999_966_663_333;

#[no_mangle]
pub extern "C" fn problem234(limit: i64) -> i64 {
    if !(0..=MAX_LIMIT).contains(&limit) { return -1; }
    let mut composite = [false; 1_000_100];
    let mut primes = [0_i64; 80_000];
    let mut prime_count = 0_usize;
    let mut root = 0_i64;
    while root + 1 <= limit / (root + 1) { root += 1; }
    let sieve_end = root as usize + 100;
    for p in 2..sieve_end {
        if composite[p] { continue; }
        primes[prime_count] = p as i64;
        prime_count += 1;
        if p * p < sieve_end {
            let mut multiple = p * p;
            while multiple < sieve_end { composite[multiple] = true; multiple += p; }
        }
    }
    let mut total = 0_i64;
    let mut index = 0_usize;
    let mut p = primes[index];
    while p * p <= limit {
        let q = primes[index + 1];
        let lower = p * p;
        let mut upper = q * q;
        let mut current = lower + p;
        while upper > current && current <= limit { total += current; current += p; }
        while upper - q > limit { upper -= q; }
        current = upper - q;
        while current > lower { total += current; current -= q; }
        current = 0;
        while upper > current && current <= limit {
            if current <= lower { current += p * q; continue; }
            if current > limit { break; }
            total -= current * 2;
            current += p * q;
        }
        p = q;
        index += 1;
    }
    total
}
