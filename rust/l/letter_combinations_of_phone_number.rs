/// Recursively enumerate 2–9 keypad letters into fixed-width concatenated slots.
fn letter_count(digit: i64) -> usize {
    if digit == 7 || digit == 9 { 4 } else { 3 }
}

fn letter_base(digit: i64) -> u8 {
    match digit {
        2 => b'a', 3 => b'd', 4 => b'g', 5 => b'j',
        6 => b'm', 7 => b'p', 8 => b't', _ => b'w',
    }
}

unsafe fn expand(digits: *const i64, length: usize, index: usize, output: *mut u8,
                 output_offset: usize, combination_count: usize) {
    if index == length { return; }
    let digit = *digits.add(index);
    let alternatives = letter_count(digit);
    let block_count = combination_count / alternatives;
    let base = letter_base(digit);
    for letter in 0..alternatives {
        let branch_offset = output_offset + letter * block_count * length;
        for row in 0..block_count {
            *output.add(branch_offset + row * length + index) = base + letter as u8;
        }
        expand(digits, length, index + 1, output, branch_offset, block_count);
    }
}

#[no_mangle]
pub extern "C" fn letter_combinations_of_phone_number(
    digits: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length == 0 { return 0; }
    if length > 6 || digits.is_null() { return -1; }
    let mut count = 1usize;
    for index in 0..length {
        let digit = unsafe { *digits.add(index) };
        if !(2..=9).contains(&digit) { return -1; }
        count *= letter_count(digit);
    }
    let required = count * length;
    if output_capacity < required || output.is_null() { return -2; }
    unsafe { expand(digits, length, 0, output, 0, count); }
    count as i64
}
