const MAX_INPUT: i64 = 100_000_000;
const SIEVE_LIMIT: usize = 10_000;
const MAX_PRIMES: usize = 1_300;
const PHI_CACHE_X: usize = 2_048;
const PHI_CACHE_S: usize = 32;

struct Context {
    composite: [u8; SIEVE_LIMIT + 1],
    primes: [i32; MAX_PRIMES],
    prime_count_prefix: [i32; SIEVE_LIMIT + 1],
    phi_cache: [[i32; PHI_CACHE_X + 1]; PHI_CACHE_S + 1],
}

fn integer_sqrt(value: u64) -> u64 {
    let (mut low, mut high) = (0_u64, value + 1);
    while low + 1 < high {
        let middle = low + (high - low) / 2;
        if middle <= value / middle { low = middle; } else { high = middle; }
    }
    low
}

fn integer_cuberoot(value: u64) -> u64 {
    let (mut low, mut high) = (0_u64, value + 1);
    while low + 1 < high {
        let middle = low + (high - low) / 2;
        if middle <= value / middle / middle { low = middle; } else { high = middle; }
    }
    low
}

fn phi(context: &mut Context, value: u64, prime_count: usize) -> i64 {
    if value == 0 { return 0; }
    if prime_count == 0 { return value as i64; }
    if prime_count == 1 { return (value - value / 2) as i64; }
    let prime = context.primes[prime_count - 1] as u64;
    if value < prime { return 1; }
    if value <= PHI_CACHE_X as u64 && prime_count <= PHI_CACHE_S {
        let cached = context.phi_cache[prime_count][value as usize];
        if cached != 0 { return cached as i64; }
        let result = phi(context, value, prime_count - 1) -
            phi(context, value / prime, prime_count - 1);
        context.phi_cache[prime_count][value as usize] = result as i32;
        return result;
    }
    phi(context, value, prime_count - 1) - phi(context, value / prime, prime_count - 1)
}

fn lehmer_count(context: &mut Context, value: u64) -> i64 {
    if value <= SIEVE_LIMIT as u64 { return context.prime_count_prefix[value as usize] as i64; }
    let a = context.prime_count_prefix[integer_sqrt(integer_sqrt(value)) as usize] as usize;
    let b = context.prime_count_prefix[integer_sqrt(value) as usize] as usize;
    let c = context.prime_count_prefix[integer_cuberoot(value) as usize] as usize;
    let mut result = phi(context, value, a) + ((b + a - 2) * (b - a + 1) / 2) as i64;
    for i in a..b {
        let quotient = value / context.primes[i] as u64;
        result -= lehmer_count(context, quotient);
        if i < c {
            let limit = lehmer_count(context, integer_sqrt(quotient)) as usize;
            for j in i..limit {
                result -= lehmer_count(context, quotient / context.primes[j] as u64) - j as i64;
            }
        }
    }
    result
}

#[no_mangle]
pub extern "C" fn meissel_lehmer_prime_count(value: i64) -> i64 {
    if !(0..=MAX_INPUT).contains(&value) { return -1; }
    let mut context = Context {
        composite: [0; SIEVE_LIMIT + 1],
        primes: [0; MAX_PRIMES],
        prime_count_prefix: [0; SIEVE_LIMIT + 1],
        phi_cache: [[0; PHI_CACHE_X + 1]; PHI_CACHE_S + 1],
    };
    for candidate in 2..=SIEVE_LIMIT {
        if context.composite[candidate] != 0 { continue; }
        if candidate <= SIEVE_LIMIT / candidate {
            for multiple in (candidate * candidate..=SIEVE_LIMIT).step_by(candidate) {
                context.composite[multiple] = 1;
            }
        }
    }
    let mut prime_count = 0;
    for candidate in 2..=SIEVE_LIMIT {
        if context.composite[candidate] == 0 {
            context.primes[prime_count] = candidate as i32;
            prime_count += 1;
        }
        context.prime_count_prefix[candidate] = context.prime_count_prefix[candidate - 1] +
            (if context.composite[candidate] == 0 { 1 } else { 0 });
    }
    lehmer_count(&mut context, value as u64)
}
