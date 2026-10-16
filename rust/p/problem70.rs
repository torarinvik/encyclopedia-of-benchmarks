const MAX_N: i64 = 10_000_000;
const PRIME_LIMIT: usize = 3162;
const PRIME_CAPACITY: usize = 500;
const SEGMENT_SIZE: usize = 32768;

fn same_digits(mut left: u32, mut right: u32) -> bool {
    let mut counts = [0i32; 10];
    while left != 0 { counts[(left % 10) as usize] += 1; left /= 10; }
    while right != 0 { counts[(right % 10) as usize] -= 1; right /= 10; }
    counts.iter().all(|&count| count == 0)
}

#[no_mangle]
pub extern "C" fn problem70(max_n: i64) -> i64 {
    if !(0..=MAX_N).contains(&max_n) { return -1; }
    let limit = max_n as u32;
    let mut prime_flags = [false; PRIME_LIMIT + 1];
    let mut primes = [0u32; PRIME_CAPACITY];
    let mut prime_count = 0usize;
    let mut value = 2usize;
    while value <= PRIME_LIMIT && value <= limit as usize / value {
        prime_flags[value] = true;
        value += 1;
    }
    let mut prime = 2usize;
    while prime <= PRIME_LIMIT && prime <= limit as usize / prime {
        if prime_flags[prime] {
            let mut multiple = prime * prime;
            while multiple <= PRIME_LIMIT && multiple <= limit as usize / multiple {
                prime_flags[multiple] = false;
                multiple += prime;
            }
        }
        prime += 1;
    }
    value = 2;
    while value <= PRIME_LIMIT && value <= limit as usize / value {
        if prime_flags[value] { primes[prime_count] = value as u32; prime_count += 1; }
        value += 1;
    }

    let mut phi = [0u32; SEGMENT_SIZE];
    let mut remainder = [0u32; SEGMENT_SIZE];
    let mut best_n = 1u32;
    let mut best_phi = 0u32;
    let mut low = 0u32;
    while low <= limit {
        let mut high = low + SEGMENT_SIZE as u32 - 1;
        if high < low || high > limit { high = limit; }
        let length = (high - low + 1) as usize;
        for offset in 0..length {
            phi[offset] = low + offset as u32;
            remainder[offset] = low + offset as u32;
        }
        for &factor in &primes[..prime_count] {
            let mut first = low + (factor - low % factor) % factor;
            if first < factor { first = factor; }
            let mut multiple = first;
            while multiple <= high {
                let offset = (multiple - low) as usize;
                phi[offset] -= phi[offset] / factor;
                while remainder[offset] % factor == 0 { remainder[offset] /= factor; }
                if high - multiple < factor { break; }
                multiple += factor;
            }
        }
        for offset in 0..length {
            if remainder[offset] > 1 { phi[offset] -= phi[offset] / remainder[offset]; }
            let number = low + offset as u32;
            if number >= 2
                && u64::from(number) * u64::from(best_phi) < u64::from(best_n) * u64::from(phi[offset])
                && same_digits(number, phi[offset])
            {
                best_n = number;
                best_phi = phi[offset];
            }
        }
        if high == limit { break; }
        low = high + 1;
    }
    i64::from(best_n)
}
