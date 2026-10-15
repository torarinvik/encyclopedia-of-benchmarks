/// Case-insensitive anagram check for distinct ASCII alphabetic strings.
const MAX_STRING_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_STRING_LENGTH;

fn letter_index(value: i64) -> Option<usize> {
    match value {
        97..=122 => Some((value - 97) as usize),
        65..=90 => Some((value - 65) as usize),
        _ => None,
    }
}

#[no_mangle]
pub extern "C" fn check_anagram(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let first_length_value = unsafe { *input };
    let second_length_value = unsafe { *input.add(1) };
    if first_length_value < 0 || first_length_value > MAX_STRING_LENGTH as i64 ||
        second_length_value < 0 || second_length_value > MAX_STRING_LENGTH as i64 { return -1; }
    let first_length = first_length_value as usize;
    let second_length = second_length_value as usize;
    if length != 2 + first_length + second_length { return -1; }
    let mut first_counts = [0usize; 26];
    let mut second_counts = [0usize; 26];
    for index in 0..first_length {
        let value = unsafe { *input.add(2 + index) };
        let Some(letter) = letter_index(value) else { return -1; };
        first_counts[letter] += 1;
    }
    for index in 0..second_length {
        let value = unsafe { *input.add(2 + first_length + index) };
        let Some(letter) = letter_index(value) else { return -1; };
        second_counts[letter] += 1;
    }
    if first_length != second_length { return 0; }
    let mut different_after_normalization = false;
    for index in 0..first_length {
        let first = letter_index(unsafe { *input.add(2 + index) }).unwrap();
        let second = letter_index(unsafe { *input.add(2 + first_length + index) }).unwrap();
        if first != second { different_after_normalization = true; }
    }
    if !different_after_normalization || first_counts != second_counts { return 0; }
    1
}
