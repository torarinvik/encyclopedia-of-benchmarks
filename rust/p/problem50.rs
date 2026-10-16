/// Return the prime below `ceiling` with the longest consecutive-prime sum.
#[no_mangle]
pub extern "C" fn problem50(ceiling: i64) -> i64 {
    if !(3..=1_000_000).contains(&ceiling) {
        return -1;
    }
    let limit = ceiling as usize;
    let mut is_prime = [true; 1_000_000];
    is_prime[0] = false;
    is_prime[1] = false;
    let mut value = 2_usize;
    while value <= (limit - 1) / value {
        if is_prime[value] {
            let mut multiple = value * value;
            while multiple < limit {
                is_prime[multiple] = false;
                multiple += value;
            }
        }
        value += 1;
    }
    let mut primes = [0_i32; 100_000];
    let mut prime_count = 0_usize;
    for candidate in 2..limit {
        if is_prime[candidate] {
            primes[prime_count] = candidate as i32;
            prime_count += 1;
        }
    }
    let mut longest = 0_usize;
    let mut largest = 0_i64;
    for start in 0..prime_count {
        let end_start = start + longest;
        let mut end = start;
        let mut sum = 0_i64;
        for finish in end_start..prime_count {
            while end < finish {
                sum += i64::from(primes[end]);
                end += 1;
            }
            if sum >= ceiling {
                break;
            }
            if is_prime[sum as usize] {
                longest = finish - start;
                largest = sum;
            }
        }
    }
    largest
}
