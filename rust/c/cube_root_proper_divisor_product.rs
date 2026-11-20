const MAX_INPUT_LENGTH: usize = 2;
const MAX_VALUE: usize = 600_000;
const MAX_K: i64 = 50_000;

fn build_prime_prefix(prefix: &mut [u32]) {
    prefix[0] = 0;
    prefix[1] = 0;
    for value in 2..=MAX_VALUE { prefix[value] = 1; }
    let mut prime = 2;
    while prime <= MAX_VALUE / prime {
        if prefix[prime] != 0 {
            let mut multiple = prime * prime;
            while multiple <= MAX_VALUE {
                prefix[multiple] = 0;
                multiple += prime;
            }
        }
        prime += 1;
    }
    for value in 1..=MAX_VALUE { prefix[value] += prefix[value - 1]; }
}

fn is_prime(value: usize, prefix: &[u32]) -> bool {
    value >= 2 && prefix[value] - prefix[value - 1] == 1
}

fn count_tau_eight(limit: usize, prefix: &[u32]) -> i64 {
    let mut count = 0_i64;
    let mut prime = 2_u64;
    loop {
        let mut power = 1_u64;
        for _ in 0..7 {
            if power > limit as u64 / prime { power = limit as u64 + 1; break; }
            power *= prime;
        }
        if power > limit as u64 { break; }
        if is_prime(prime as usize, prefix) { count += 1; }
        prime += 1;
    }
    prime = 2;
    loop {
        let cube = prime * prime * prime;
        if cube > limit as u64 { break; }
        if is_prime(prime as usize, prefix) {
            let q_max = (limit as u64 / cube) as usize;
            count += prefix[q_max] as i64;
            if prime as usize <= q_max { count -= 1; }
        }
        prime += 1;
    }
    prime = 2;
    while prime * prime * prime < limit as u64 {
        if is_prime(prime as usize, prefix) {
            let mut other = prime + 1;
            loop {
                if prime > limit as u64 / other { break; }
                let product = prime * other;
                let last_prime = (limit as u64 / product) as usize;
                if last_prime as u64 <= other { break; }
                if is_prime(other as usize, prefix) {
                    count += (prefix[last_prime] - prefix[other as usize]) as i64;
                }
                other += 1;
            }
        }
        prime += 1;
    }
    count
}

fn sequence_term(k: i64) -> i64 {
    if k == 1 { return 1; }
    let mut prefix = [0_u32; MAX_VALUE + 1];
    build_prime_prefix(&mut prefix);
    let target = k - 1;
    if count_tau_eight(MAX_VALUE, &prefix) < target { return -1; }
    let mut low = 1_usize;
    let mut high = MAX_VALUE;
    while low < high {
        let middle = low + (high - low) / 2;
        if count_tau_eight(middle, &prefix) >= target { high = middle; }
        else { low = middle + 1; }
    }
    low as i64
}

#[no_mangle]
pub unsafe extern "C" fn cube_root_proper_divisor_product(
    input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if length != 1 || values[0] < 1 || values[0] > MAX_K { return -1; }
    sequence_term(values[0])
}
