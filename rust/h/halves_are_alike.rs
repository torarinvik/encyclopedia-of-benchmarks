/// Compare the vowel counts in two equal ASCII-letter halves.
#[no_mangle]
pub extern "C" fn halves_are_alike(letters: *const i64, length: usize) -> i64 {
    if length > 256 || length % 2 != 0 {
        return -1;
    }
    if length == 0 {
        return 1;
    }
    let letters = unsafe { std::slice::from_raw_parts(letters, length) };
    let half = length / 2;
    let mut first = 0;
    let mut second = 0;
    for (index, &value) in letters.iter().enumerate() {
        if !((65..=90).contains(&value) || (97..=122).contains(&value)) {
            return -1;
        }
        if matches!(value, 65 | 69 | 73 | 79 | 85 | 97 | 101 | 105 | 111 | 117) {
            if index < half { first += 1; }
            else { second += 1; }
        }
    }
    if first == second { 1 } else { 0 }
}
