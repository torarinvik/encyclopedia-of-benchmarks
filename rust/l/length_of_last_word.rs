#[no_mangle]
pub extern "C" fn length_of_last_word(input: *const i64, length: usize) -> i64 {
    if length < 1 || length > 129 || input.is_null() { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 0 || input[0] > 128 || length != input[0] as usize + 1 { return -1; }
    if input[1..].iter().any(|&value| !(0..=255).contains(&value)) { return -1; }
    let mut index = input[0] as usize;
    while index > 0 && input[index] == 32 { index -= 1; }
    let mut word_length = 0_i64;
    while index > 0 && input[index] != 32 {
        word_length += 1;
        index -= 1;
    }
    word_length
}
