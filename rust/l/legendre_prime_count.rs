const MAX_INPUT: i64 = 10_000;

fn legendre_phi(primes: &[i64], value: i64, count: usize) -> i64 {
    if value == 0 { return 0; }
    if count == 0 { return value; }
    if count == 1 { return value - value / 2; }
    let prime = primes[count - 1];
    if value < prime { return 1; }
    legendre_phi(primes, value, count - 1) - legendre_phi(primes, value / prime, count - 1)
}

#[no_mangle]
pub extern "C" fn legendre_prime_count(value: i64) -> i64 {
    if value < 0 || value > MAX_INPUT { return -1; }
    if value < 2 { return 0; }
    let mut root = 0i64;
    while (root + 1) * (root + 1) <= value { root += 1; }
    let mut composite = [false; 101];
    let mut candidate = 2i64;
    while candidate * candidate <= root {
        if !composite[candidate as usize] {
            let mut multiple = candidate * candidate;
            while multiple <= root {
                composite[multiple as usize] = true;
                multiple += candidate;
            }
        }
        candidate += 1;
    }
    let mut primes = [0i64; 25];
    let mut count = 0usize;
    for candidate in 2..=root as usize {
        if !composite[candidate] {
            primes[count] = candidate as i64;
            count += 1;
        }
    }
    legendre_phi(&primes[..count], value, count) + count as i64 - 1
}
