#[no_mangle]
pub extern "C" fn problem77(threshold: i64) -> i64 {
    if !(0..=100_000).contains(&threshold) { return -1; }
    let mut partitions = [0i64; 100];
    partitions[0] = 1;
    for prime in 2..100 {
        let mut is_prime = true;
        for divisor in 2..=((prime as f64).sqrt() as usize) {
            if prime % divisor == 0 { is_prime = false; break; }
        }
        if is_prime {
            for total in prime..100 { partitions[total] += partitions[total - prime]; }
        }
    }
    for value in 1..100 { if partitions[value] > threshold { return value as i64; } }
    -1
}
