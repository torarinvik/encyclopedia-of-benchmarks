/// Compare lowercase ASCII strings by their letter frequencies.
const MAX_STRING_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_STRING_LENGTH;

#[no_mangle]
pub extern "C" fn valid_anagram(input: *const i64, length: usize) -> i64 {
    if length < 2 || length > MAX_INPUT_LENGTH || input.is_null() { return -1; }
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
        if !(97..=122).contains(&value) { return -1; }
        first_counts[(value - 97) as usize] += 1;
    }
    for index in 0..second_length {
        let value = unsafe { *input.add(2 + first_length + index) };
        if !(97..=122).contains(&value) { return -1; }
        second_counts[(value - 97) as usize] += 1;
    }
    if first_counts != second_counts { return 0; }
    1
}
