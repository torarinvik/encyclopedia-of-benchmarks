const MAX_PHRASE_LENGTH: usize = 79;

#[no_mangle]
pub unsafe extern "C" fn acronym(
    phrase: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length > MAX_PHRASE_LENGTH { return -1; }
    if length == 0 { return 0; }
    let phrase = std::slice::from_raw_parts(phrase, length);
    if phrase.iter().any(|&value| !(1..=127).contains(&value)) { return -1; }
    let mut required = 0usize;
    for (index, &value) in phrase.iter().enumerate() {
        if value != 32 && (index == 0 || phrase[index - 1] == 32) { required += 1; }
    }
    if output_capacity < required || (required != 0 && output.is_null()) { return -2; }
    let mut written = 0usize;
    for (index, &value) in phrase.iter().enumerate() {
        if value != 32 && (index == 0 || phrase[index - 1] == 32) {
            let initial = if (97..=122).contains(&value) { value - 32 } else { value };
            *output.add(written) = initial as u8;
            written += 1;
        }
    }
    written as i64
}
