fn decimal_length(mut value: i64) -> usize {
    let mut length = 1usize;
    while value >= 10 { value /= 10; length += 1; }
    length
}

fn required_length(value: i64) -> usize {
    let mut length = 0usize;
    let mut count = 0usize;
    let mut remaining = value;
    let mut divisor = 2i64;
    while divisor <= remaining / divisor {
        while remaining % divisor == 0 {
            length += decimal_length(divisor) + usize::from(count > 0);
            count += 1;
            remaining /= divisor;
        }
        divisor += 1;
    }
    if remaining > 1 { length += decimal_length(remaining) + usize::from(count > 0); }
    length
}

fn append_decimal(mut value: i64, output: *mut u8, mut position: usize) -> usize {
    let mut digits = [0u8; 10];
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

/// Encode prime factors in ascending order, retaining multiplicity.
#[no_mangle]
pub extern "C" fn prime_factors(value: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(1..=2147483647).contains(&value) { return -1; }
    let required = required_length(value);
    if output.is_null() || output_capacity < required { return -2; }
    let mut position = 0usize;
    let mut count = 0usize;
    let mut remaining = value;
    let mut divisor = 2i64;
    while divisor <= remaining / divisor {
        while remaining % divisor == 0 {
            if count > 0 { unsafe { output.add(position).write(b','); } position += 1; }
            position = append_decimal(divisor, output, position);
            count += 1;
            remaining /= divisor;
        }
        divisor += 1;
    }
    if remaining > 1 {
        if count > 0 { unsafe { output.add(position).write(b','); } position += 1; }
        position = append_decimal(remaining, output, position);
    }
    position as i64
}
