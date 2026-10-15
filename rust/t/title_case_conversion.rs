/// Apply the pinned JavaScript title-case behavior to bounded ASCII words.
const MAX_LENGTH: usize = 256;

#[no_mangle]
pub extern "C" fn title_case_conversion(input: *const i64, length: usize,
                                          output: *mut u8, output_capacity: usize) -> i64 {
    if length == 0 || length > MAX_LENGTH + 1 || input.is_null() { return -1; }
    let declared = unsafe { *input };
    if declared < 0 || declared > MAX_LENGTH as i64 || length != declared as usize + 1 { return -1; }
    for index in 0..declared as usize {
        let value = unsafe { *input.add(index + 1) };
        let letter = (65..=90).contains(&value) || (97..=122).contains(&value);
        if !letter && value != 32 { return -1; }
        if value == 32 && (index == 0 || index + 1 == declared as usize || unsafe { *input.add(index) } == 32) { return -1; }
    }
    if output_capacity < declared as usize + 1 { return -2; }
    let mut at_word_start = true;
    for index in 0..declared as usize {
        let mut value = unsafe { *input.add(index + 1) };
        if value == 32 { at_word_start = true; }
        else if at_word_start {
            if (97..=122).contains(&value) { value -= 32; }
            at_word_start = false;
        } else if (65..=90).contains(&value) { value += 32; }
        unsafe { *output.add(index) = value as u8; }
    }
    unsafe { *output.add(declared as usize) = 0; }
    declared
}
