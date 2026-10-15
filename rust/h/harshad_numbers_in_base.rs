const MAX_LIMIT: i64 = 10000;

fn digit_sum(number_value: i64, base: i64) -> i64 {
    let mut remaining = number_value;
    let mut sum = 0;
    while remaining > 0 {
        sum += remaining % base;
        remaining /= base;
    }
    sum
}

fn base_length(number_value: i64, base: i64) -> usize {
    let mut remaining = number_value;
    let mut length = 0;
    while remaining > 0 {
        length += 1;
        remaining /= base;
    }
    length
}

fn required_length(limit: i64, base: i64) -> usize {
    let mut length = 0;
    let mut number = 1;
    while number < limit {
        if number % digit_sum(number, base) == 0 {
            length += base_length(number, base) + 1;
        }
        number += 1;
    }
    length
}

fn digit_byte(digit: i64) -> u8 {
    if digit < 10 { b'0' + digit as u8 } else { b'A' + (digit - 10) as u8 }
}

fn append_base(mut number: i64, base: i64, output: *mut u8, mut position: usize) -> usize {
    let mut digits = [0u8; 64];
    let mut count = 0;
    while number > 0 {
        digits[count] = digit_byte(number % base);
        count += 1;
        number /= base;
    }
    while count > 0 {
        count -= 1;
        unsafe { output.add(position).write(digits[count]); }
        position += 1;
    }
    position
}

/// Encode each source string as uppercase base digits followed by a NUL byte.
#[no_mangle]
pub extern "C" fn harshad_numbers_in_base(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let (limit, base) = unsafe { (*values, *values.add(1)) };
    if limit > MAX_LIMIT || !(2..=36).contains(&base) { return -1; }
    let required = required_length(limit, base);
    if output.is_null() || output_capacity < required { return -2; }
    let mut position = 0;
    let mut number = 1;
    while number < limit {
        if number % digit_sum(number, base) == 0 {
            position = append_base(number, base, output, position);
            unsafe { output.add(position).write(0); }
            position += 1;
        }
        number += 1;
    }
    position as i64
}
