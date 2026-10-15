fn decimal_length(mut value: i64) -> usize {
    let mut length = 1usize;
    while value >= 10 { value /= 10; length += 1; }
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

/// List all positive divisors in ascending decimal order.
#[no_mangle]
pub extern "C" fn factors(value: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(1..=256).contains(&value) { return -1; }
    let mut required = 0usize;
    let mut count = 0usize;
    for divisor in 1..=value {
        if value % divisor == 0 {
            required += decimal_length(divisor) + usize::from(count > 0);
            count += 1;
        }
    }
    if output.is_null() || output_capacity < required { return -2; }
    let mut position = 0usize;
    count = 0;
    for divisor in 1..=value {
        if value % divisor == 0 {
            if count > 0 { unsafe { output.add(position).write(b','); } position += 1; }
            position = append_decimal(divisor, output, position);
            count += 1;
        }
    }
    position as i64
}
