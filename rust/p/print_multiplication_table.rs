/// Format a bounded multiplication table as source-faithful ASCII lines.
fn decimal_length(value: i64) -> usize {
    let mut magnitude = value.abs();
    let mut length = 1;
    if value < 0 { length += 1; }
    while magnitude >= 10 { magnitude /= 10; length += 1; }
    length
}

unsafe fn append_decimal(output: *mut u8, position: &mut usize, value: i64) {
    let mut magnitude = value.abs();
    if value < 0 {
        output.add(*position).write(b'-');
        *position += 1;
    }
    let mut reversed = [0u8; 20];
    let mut count = 0usize;
    loop {
        reversed[count] = b'0' + (magnitude % 10) as u8;
        count += 1;
        magnitude /= 10;
        if magnitude == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        output.add(*position).write(reversed[count]);
        *position += 1;
    }
}

#[no_mangle]
pub extern "C" fn print_multiplication_table(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let number = values[0];
    let terms = values[1];
    if !(-1_000_000..=1_000_000).contains(&number) || !(-20..=20).contains(&terms) { return -1; }
    let mut required = if terms > 0 { (terms - 1) as usize } else { 0 };
    for multiplier in 1..=terms {
        let product = number * multiplier;
        required += decimal_length(number) + 3 + decimal_length(multiplier) + 3 + decimal_length(product);
    }
    if output_capacity < required || (required > 0 && output.is_null()) { return -2; }
    let mut position = 0usize;
    for multiplier in 1..=terms {
        unsafe {
            if multiplier > 1 { output.add(position).write(b'\n'); position += 1; }
            append_decimal(output, &mut position, number);
            output.add(position).write(b' '); output.add(position + 1).write(b'*'); output.add(position + 2).write(b' ');
            position += 3;
            append_decimal(output, &mut position, multiplier);
            output.add(position).write(b' '); output.add(position + 1).write(b'='); output.add(position + 2).write(b' ');
            position += 3;
            append_decimal(output, &mut position, number * multiplier);
        }
    }
    position as i64
}
