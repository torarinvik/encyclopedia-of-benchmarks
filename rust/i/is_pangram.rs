/// ASCII pangram predicate: ignore nonletters and ASCII letter case.
#[no_mangle]
pub extern "C" fn is_pangram(values: *const i64, length: usize) -> i64 {
    if length > 4096 || (length != 0 && values.is_null()) { return -1; }
    if length == 0 { return 0; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut seen = [false; 26];
    let mut found = 0;
    for &value in values {
        if !(0..=127).contains(&value) { return -1; }
        let lower = if (65..=90).contains(&value) { value + 32 } else { value };
        if (97..=122).contains(&lower) {
            let letter = (lower - 97) as usize;
            if !seen[letter] {
                seen[letter] = true;
                found += 1;
            }
        }
    }
    if found == 26 { 1 } else { 0 }
}
