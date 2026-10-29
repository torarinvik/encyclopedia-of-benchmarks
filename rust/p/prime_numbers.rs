fn is_prime(value: i64) -> bool {
    if value < 2 { return false; }
    let mut divisor = 2i64;
    let mut quotient = value / divisor;
    while divisor <= quotient {
        if value - quotient * divisor == 0 { return false; }
        divisor += 1;
        quotient = value / divisor;
    }
    true
}

fn decimal_length(mut value: i64) -> usize {
    let mut length = 1usize;
    while value >= 10 { value /= 10; length += 1; }
    length
}

fn required_length(limit: i64) -> usize {
    let mut length = 0usize;
    let mut count = 0usize;
    for value in 2..=limit {
        if is_prime(value) {
            length += decimal_length(value) + usize::from(count > 0);
            count += 1;
        }
    }
    length
}

fn append_decimal(mut value: i64, output: *mut u8, mut position: usize) -> usize {
    let mut digits = [0u8; 3];
    let mut count = 0usize;
    while value > 0 {
        digits[count] = (value % 10) as u8;
        count += 1;
        value /= 10;
    }
    while count > 0 {
        count -= 1;
        unsafe { output.add(position).write(b'0' + digits[count]); }
        position += 1;
    }
    position
}

/// Encode all primes through an inclusive limit as comma-separated decimal bytes.
#[no_mangle]
pub extern "C" fn prime_numbers(limit: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(0..=80).contains(&limit) { return -1; }
    let required = required_length(limit);
    if output.is_null() || output_capacity < required { return -2; }
    let mut position = 0usize;
    let mut count = 0usize;
    for value in 2..=limit {
        if is_prime(value) {
            if count > 0 { unsafe { output.add(position).write(b','); } position += 1; }
            position = append_decimal(value, output, position);
            count += 1;
        }
    }
    position as i64
}
