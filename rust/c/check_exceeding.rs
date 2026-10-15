/// Check nondecreasing letter gaps after ASCII normalization and filtering.
const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn check_exceeding(values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) { return -2; }
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if !(32..=126).contains(&value) { return -2; }
    }

    let mut previous_letter = -1i64;
    let mut previous_gap = -1i64;
    for index in 0..length {
        let mut letter = unsafe { *values.add(index) };
        if (97..=122).contains(&letter) { letter -= 32; }
        if !(65..=90).contains(&letter) { continue; }
        if previous_letter >= 0 && letter != previous_letter {
            let gap = (letter - previous_letter).abs();
            if previous_gap >= 0 && gap < previous_gap { return 0; }
            previous_gap = gap;
        }
        previous_letter = letter;
    }
    1
}
