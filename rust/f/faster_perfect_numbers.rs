const MAX_INPUT: i64 = 2_305_843_009_213_693_951;

fn get_prime_limit(value: i64) -> u64 {
    let mut scaled = value as u64 * 8 + 1;
    let mut limit = 0;
    while scaled >= 4 {
        scaled /= 4;
        limit += 1;
    }
    limit
}

fn is_prime(value: u64) -> bool {
    if value < 2 { return false; }
    let mut divisor = 2;
    while divisor * divisor <= value {
        if value % divisor == 0 { return false; }
        divisor += 1;
    }
    true
}

fn is_mersenne_prime(exponent: u64) -> bool {
    if exponent == 2 { return true; }
    if exponent < 2 { return false; }
    let modulus = (1u64 << exponent) - 1;
    let mut residue = 4u64;
    for _ in 0..(exponent - 2) {
        residue = (residue * residue - 2) % modulus;
    }
    residue == 0
}

#[no_mangle]
pub extern "C" fn faster_perfect_numbers(
    value: i64,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if !(0..=MAX_INPUT).contains(&value) { return -1; }
    let mut perfects = [0i64; 8];
    let mut count = 0usize;
    let limit = get_prime_limit(value);
    for exponent in 2..=limit {
        if !is_prime(exponent) || !is_mersenne_prime(exponent) { continue; }
        let mersenne = (1u64 << exponent) - 1;
        let perfect = mersenne * (1u64 << (exponent - 1));
        if perfect <= value as u64 {
            perfects[count] = perfect as i64;
            count += 1;
        }
    }
    let required = count * 8;
    if (required > 0 && output.is_null()) || output_capacity < required { return -2; }
    for index in 0..count {
        let bits = perfects[index] as u64;
        for byte in 0..8 {
            unsafe { *output.add(index * 8 + byte) = (bits >> (byte * 8)) as u8; }
        }
    }
    required as i64
}
