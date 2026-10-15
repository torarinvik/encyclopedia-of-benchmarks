fn roman_digit_length(digit: i64) -> usize {
    if digit == 4 || digit == 9 { return 2; }
    if digit >= 5 { return (digit - 4) as usize; }
    digit as usize
}

fn append_roman_digit(mut digit: i64, one: u8, five: u8, ten: u8,
                      output: *mut u8, mut position: usize) -> usize {
    if digit == 9 {
        unsafe { output.add(position).write(one); output.add(position + 1).write(ten); }
        return position + 2;
    }
    if digit >= 5 {
        unsafe { output.add(position).write(five); }
        position += 1;
        digit -= 5;
    }
    if digit == 4 {
        unsafe { output.add(position).write(one); output.add(position + 1).write(five); }
        return position + 2;
    }
    while digit > 0 {
        unsafe { output.add(position).write(one); }
        position += 1;
        digit -= 1;
    }
    position
}

/// Encode an integer in canonical uppercase Roman numerals.
#[no_mangle]
pub extern "C" fn integer_to_roman(value: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(1..=3999).contains(&value) { return -1; }
    let width = (value / 1000) as usize + roman_digit_length((value / 100) % 10) +
        roman_digit_length((value / 10) % 10) + roman_digit_length(value % 10);
    if output.is_null() || output_capacity < width { return -2; }
    let mut position = 0usize;
    for _ in 0..value / 1000 { unsafe { output.add(position).write(b'M'); } position += 1; }
    position = append_roman_digit((value / 100) % 10, b'C', b'D', b'M', output, position);
    position = append_roman_digit((value / 10) % 10, b'X', b'L', b'C', output, position);
    position = append_roman_digit(value % 10, b'I', b'V', b'X', output, position);
    position as i64
}
