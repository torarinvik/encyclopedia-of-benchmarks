/// Count the primes through limit using the Sieve of Eratosthenes.
#[no_mangle]
pub extern "C" fn sieve_of_eratosthenes(limit: i64) -> i64 {
    if !(0..=4096).contains(&limit) {
        return -1;
    }
    if limit < 2 {
        return 0;
    }
    let mut prime = [false; 4097];
    for value in 2..=limit as usize {
        prime[value] = true;
    }
    let mut factor = 2usize;
    while factor <= limit as usize / factor {
        if prime[factor] {
            let mut multiple = factor * factor;
            while multiple <= limit as usize {
                prime[multiple] = false;
                multiple += factor;
            }
        }
        factor += 1;
    }
    prime[2..=limit as usize].iter().filter(|&&value| value).count() as i64
}
