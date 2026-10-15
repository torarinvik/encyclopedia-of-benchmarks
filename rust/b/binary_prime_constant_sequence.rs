const MAX_COUNT: i64 = 4096;

fn is_prime(candidate: i64) -> bool {
    if candidate < 2 { return false; }
    let mut divisor = 2;
    while divisor <= candidate / divisor {
        if candidate % divisor == 0 { return false; }
        divisor += 1;
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn binary_prime_constant_sequence(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let count_value = *input;
    if !(0..=MAX_COUNT).contains(&count_value) { return -1; }
    let count = count_value as usize;
    if output_capacity < count || (count > 0 && output.is_null()) { return -2; }

    let mut next = 1usize;
    let mut candidate = 2i64;
    while candidate <= count_value {
        if is_prime(candidate) {
            while next < candidate as usize {
                *output.add(next - 1) = 0;
                next += 1;
            }
            *output.add(candidate as usize - 1) = 1;
            next = candidate as usize + 1;
        }
        candidate += 1;
    }
    while next <= count {
        *output.add(next - 1) = 0;
        next += 1;
    }
    count as i64
}
