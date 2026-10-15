/// Generate zero-based prime terms using divisibility by all earlier primes.
#[no_mangle]
pub extern "C" fn primes_sequence(index: i64) -> i64 {
    if !(0..=99).contains(&index) {
        return -1;
    }
    let mut primes = [0i64; 100];
    primes[0] = 2;
    let mut count = 1usize;
    let mut candidate = 3i64;
    while count <= index as usize {
        let mut is_prime = true;
        for i in 0..count {
            if candidate % primes[i] == 0 {
                is_prime = false;
                break;
            }
        }
        if is_prime {
            primes[count] = candidate;
            count += 1;
        }
        candidate += 2;
    }
    primes[index as usize]
}
