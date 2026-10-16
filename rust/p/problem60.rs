const MAX_PRIMES: usize = 1000;
const TARGET_SIZE: usize = 5;
const PAIR_CACHE_SIZE: usize = MAX_PRIMES * MAX_PRIMES;

fn is_prime(value: i64) -> bool {
    if value < 2 { return false; }
    if value == 2 || value == 3 { return true; }
    if value % 2 == 0 || value % 3 == 0 { return false; }
    let mut divisor = 5i64;
    while divisor <= value / divisor {
        if value % divisor == 0 || value % (divisor + 2) == 0 { return false; }
        divisor += 6;
    }
    true
}

fn concatenate(left: i64, right: i64) -> i64 {
    let mut scale = 10i64;
    while scale <= right { scale *= 10; }
    left * scale + right
}

fn pair_works(primes: &[i64; MAX_PRIMES], cache: &mut [u8; PAIR_CACHE_SIZE],
              left_index: usize, right_index: usize) -> bool {
    let key = left_index * MAX_PRIMES + right_index;
    if cache[key] != 0 { return cache[key] == 2; }
    let reverse_key = right_index * MAX_PRIMES + left_index;
    if cache[reverse_key] != 0 { return cache[reverse_key] == 2; }
    let left = primes[left_index];
    let right = primes[right_index];
    let result = is_prime(concatenate(left, right)) && is_prime(concatenate(right, left));
    let state: u8 = if result { 2 } else { 1 };
    cache[key] = state;
    cache[reverse_key] = state;
    result
}

fn search_set(primes: &[i64; MAX_PRIMES], prime_count: usize,
              cache: &mut [u8; PAIR_CACHE_SIZE], chain: &mut [usize; TARGET_SIZE],
              depth: usize, start: usize, sum: i64) -> i64 {
    if depth == TARGET_SIZE { return sum; }
    for candidate in start..prime_count {
        let mut compatible = true;
        for member in 0..depth {
            if !pair_works(primes, cache, candidate, chain[member]) {
                compatible = false;
                break;
            }
        }
        if !compatible { continue; }
        chain[depth] = candidate;
        let result = search_set(primes, prime_count, cache, chain,
                                depth + 1, candidate + 1, sum + primes[candidate]);
        if result != 0 { return result; }
    }
    0
}

#[no_mangle]
pub extern "C" fn problem60(placeholder: i64) -> i64 {
    if placeholder != 0 { return -1; }
    let mut primes = [0i64; MAX_PRIMES];
    primes[..4].copy_from_slice(&[3, 7, 13, 19]);
    let mut prime_count = 4usize;
    while prime_count < MAX_PRIMES {
        let mut candidate = primes[prime_count - 1] + 3;
        while !is_prime(candidate) { candidate += 3; }
        primes[prime_count] = candidate;
        prime_count += 1;
    }
    let mut cache = [0u8; PAIR_CACHE_SIZE];
    let mut chain = [0usize; TARGET_SIZE];
    for start in 0..prime_count {
        chain[0] = start;
        let result = search_set(&primes, prime_count, &mut cache, &mut chain,
                                1, start + 1, primes[start]);
        if result != 0 { return result; }
    }
    -1
}
