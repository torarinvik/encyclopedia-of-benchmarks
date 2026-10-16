const MAX_INPUT: i64 = 4096;
const MAX_DISTINCT_FACTORS: usize = 5;

fn is_prime_by_source_trial_division(candidate: i64) -> bool {
    if candidate == 2 {
        return true;
    }
    let half_candidate = candidate / 2 + 1;
    let mut divisor = 2_i64;
    while divisor <= half_candidate {
        if candidate % divisor == 0 {
            return false;
        }
        if divisor == half_candidate {
            return true;
        }
        divisor += 1;
    }
    false
}

#[no_mangle]
pub extern "C" fn prime_factorial(value: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(2..=MAX_INPUT).contains(&value) {
        return -1;
    }
    let mut factors = [0_u32; MAX_DISTINCT_FACTORS];
    let mut count = 0_usize;
    for candidate in 2..=value {
        if is_prime_by_source_trial_division(candidate) && value % candidate == 0 {
            factors[count] = candidate as u32;
            count += 1;
        }
    }
    let required = count * 4;
    if output.is_null() || output_capacity < required {
        return -2;
    }
    let mut position = 0_usize;
    for factor in factors.iter().take(count) {
        for byte in factor.to_le_bytes() {
            unsafe { output.add(position).write(byte); }
            position += 1;
        }
    }
    position as i64
}
