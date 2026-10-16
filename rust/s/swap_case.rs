const MAX_INPUT_LENGTH: usize = 4096;

#[no_mangle]
pub unsafe extern "C" fn swap_case(input: *const i64, length: usize,
                                    output: *mut u8, capacity: usize) -> i64 {
    if length > MAX_INPUT_LENGTH || (length != 0 && input.is_null()) { return -1; }
    for i in 0..length {
        let value = *input.add(i);
        if !(0..=127).contains(&value) { return -1; }
    }
    if length > capacity || (length != 0 && output.is_null()) { return -2; }
    for i in 0..length {
        let mut value = *input.add(i);
        if (65..=90).contains(&value) { value += 32; }
        else if (97..=122).contains(&value) { value -= 32; }
        *output.add(i) = value as u8;
    }
    length as i64
}
