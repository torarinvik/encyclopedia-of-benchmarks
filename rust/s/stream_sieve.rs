use std::sync::Mutex;

const MAX_PRIMES: usize = 100;

struct PrimeCache {
    primes: [i32; MAX_PRIMES],
    count: usize,
    next_candidate: i32,
}

impl PrimeCache {
    const fn new() -> Self {
        Self { primes: [0; MAX_PRIMES], count: 0, next_candidate: 3 }
    }

    fn is_prime_candidate(&self, candidate: i32) -> bool {
        for &divisor in &self.primes[..self.count] {
            if divisor > candidate / divisor { break; }
            if candidate % divisor == 0 { return false; }
        }
        true
    }

    fn extend(&mut self, requested_count: usize) {
        if self.count == 0 {
            self.primes[0] = 2;
            self.count = 1;
        }
        while self.count < requested_count {
            let candidate = self.next_candidate;
            self.next_candidate += 1;
            if self.is_prime_candidate(candidate) {
                self.primes[self.count] = candidate;
                self.count += 1;
            }
        }
    }
}

static PRIME_CACHE: Mutex<PrimeCache> = Mutex::new(PrimeCache::new());

#[no_mangle]
pub extern "C" fn stream_sieve(
    number_of_primes: i64,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if number_of_primes < i32::MIN as i64 || number_of_primes > MAX_PRIMES as i64 {
        return -1;
    }
    if number_of_primes <= 0 { return 0; }
    let count = number_of_primes as usize;
    let required = count * 4;
    if output.is_null() || output_capacity < required { return -2; }

    let mut cache = PRIME_CACHE.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
    cache.extend(count);
    for index in 0..count {
        let bits = cache.primes[index] as u32;
        for byte in 0..4 {
            unsafe { *output.add(index * 4 + byte) = (bits >> (byte * 8)) as u8; }
        }
    }
    required as i64
}
