/// Emit the first n Fibonacci terms as decimal NUL-terminated values.
const MIN_COUNT: i64 = 3;
const MAX_COUNT: i64 = 79;

fn decimal_length(mut number: i64) -> usize {
    let mut length = 1;
    while number >= 10 { number /= 10; length += 1; }
    length
}

fn required_length(count: i64) -> usize {
    let mut bytes = 0;
    let (mut previous, mut current) = (0_i64, 1_i64);
    for index in 0..count {
        let value = if index == 0 { 0 } else if index == 1 { 1 } else {
            let next = previous + current;
            previous = current;
            current = next;
            next
        };
        bytes += decimal_length(value) + 1;
    }
    bytes
}

fn append_decimal(mut number: i64, output: *mut u8, mut position: usize) -> usize {
    let mut digits = [0_u8; 20];
    let mut count = 0;
    while number > 0 { digits[count] = b'0' + (number % 10) as u8; count += 1; number /= 10; }
    if count == 0 { digits[0] = b'0'; count = 1; }
    while count > 0 { count -= 1; unsafe { output.add(position).write(digits[count]); } position += 1; }
    position
}

#[no_mangle]
pub extern "C" fn first_n_fibonacci(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length != 1 { return -1; }
    let count = unsafe { *values };
    if !(MIN_COUNT..=MAX_COUNT).contains(&count) { return -1; }
    let required = required_length(count);
    if output.is_null() || output_capacity < required { return -2; }
    let (mut previous, mut current) = (0_i64, 1_i64);
    let mut position = 0;
    for index in 0..count {
        let value = if index == 0 { 0 } else if index == 1 { 1 } else {
            let next = previous + current;
            previous = current;
            current = next;
            next
        };
        position = append_decimal(value, output, position);
        unsafe { output.add(position).write(0); }
        position += 1;
    }
    position as i64
}
