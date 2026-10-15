/// Enumerate Kaprekar numbers as decimal NUL-terminated values.
const MAX_END: i64 = 100_000;

fn is_kaprekar(number: i64) -> bool {
    if number == 0 || number == 1 { return true; }
    let square = number * number;
    let mut split = 1_i64;
    let mut remaining = number;
    while remaining > 0 { split *= 10; remaining /= 10; }
    let right = square % split;
    right != 0 && square / split + right == number
}

fn decimal_length(mut number: i64) -> usize {
    let mut length = 1;
    while number >= 10 { number /= 10; length += 1; }
    length
}

fn required_length(start: i64, end: i64) -> usize {
    let mut bytes = 0;
    let mut number = start;
    while number <= end {
        if is_kaprekar(number) { bytes += decimal_length(number) + 1; }
        number += 1;
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

/// Return the byte count, or -1 for invalid input and -2 for insufficient output capacity.
#[no_mangle]
pub extern "C" fn kaprekar_numbers_in_range(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let start = unsafe { *values };
    let end = unsafe { *values.add(1) };
    if start < 0 || start > end || end > MAX_END { return -1; }
    let required = required_length(start, end);
    if output.is_null() || output_capacity < required { return -2; }
    let mut position = 0;
    let mut number = start;
    while number <= end {
        if is_kaprekar(number) {
            position = append_decimal(number, output, position);
            unsafe { output.add(position).write(0); }
            position += 1;
        }
        number += 1;
    }
    position as i64
}
