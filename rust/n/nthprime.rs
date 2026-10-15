/// Expanding sieve strategy from the pinned Rust nth-prime routine.
#[no_mangle]
pub extern "C" fn nthprime(nth: i64) -> i64 {
    if !(1..=100).contains(&nth) {
        return -1;
    }
    let mut primes = [0u64; 1600];
    let mut total_prime = 0u64;
    let mut size_factor = 2u64;
    let mut size = nth as usize * size_factor as usize;

    while total_prime < nth as u64 {
        if size > primes.len() {
            return -1;
        }
        primes[..size].fill(1);
        for index in 2..size {
            if primes[index] == 1 {
                for multiple in index..size {
                    let product = index * multiple;
                    if product < size {
                        primes[product] = 0;
                    } else {
                        break;
                    }
                }
            }
        }
        total_prime = primes[2..size].iter().sum();
        size_factor += 1;
        size = nth as usize * size_factor as usize;
    }

    let used_size = size - nth as usize;
    let mut count = 0u64;
    for index in 2..used_size {
        count += primes[index];
        if count == nth as u64 {
            return index as i64;
        }
    }
    -1
}
