const MAX_INPUT_LENGTH: usize = 2;
const MAX_SIEVE_LIMIT: usize = 1_000;

fn accumulate_powerful(
    n: i64,
    primes: &[i64; MAX_SIEVE_LIMIT + 1],
    prime_count: usize,
    start_index: usize,
    product: i64,
    h_product: i64,
    total: &mut i64,
) {
    let remaining = n / product;
    for prime_index in start_index..prime_count {
        let prime = primes[prime_index];
        if prime > remaining / prime {
            break;
        }
        let mut prime_power = prime * prime;
        let mut h_power = prime - 1;
        while prime_power <= remaining {
            let next_product = product * prime_power;
            let next_h_product = h_product * h_power;
            *total += next_h_product * (n / next_product);
            accumulate_powerful(
                n,
                primes,
                prime_count,
                prime_index + 1,
                next_product,
                next_h_product,
                total,
            );
            if prime_power > remaining / prime {
                break;
            }
            prime_power *= prime;
            h_power *= prime;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn powerful_number_summatory_sieve(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    if length != 1 {
        return -1;
    }
    let n = *input;
    if !(1..=1_000_000).contains(&n) {
        return -1;
    }

    let mut limit = 1usize;
    while limit + 1 <= n as usize / (limit + 1) {
        limit += 1;
    }
    let mut composite = [false; MAX_SIEVE_LIMIT + 1];
    let mut primes = [0_i64; MAX_SIEVE_LIMIT + 1];
    let mut prime_count = 0usize;
    for candidate in 2..=limit {
        if !composite[candidate] {
            primes[prime_count] = candidate as i64;
            prime_count += 1;
            if candidate <= limit / candidate {
                let mut multiple = candidate * candidate;
                while multiple <= limit {
                    composite[multiple] = true;
                    multiple += candidate;
                }
            }
        }
    }

    let mut total = n; // The d=1 term contributes h(1)*N = N.
    accumulate_powerful(n, &primes, prime_count, 0, 1, 1, &mut total);
    total
}
