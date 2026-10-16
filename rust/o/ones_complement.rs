const MAX_INPUT_LENGTH: usize = 64;

#[no_mangle]
pub unsafe extern "C" fn ones_complement(input: *const i64, length: usize,
                                          output: *mut u8, capacity: usize) -> i64 {
    if length == 0 || length > MAX_INPUT_LENGTH || input.is_null() { return -1; }
    for i in 0..length {
        let value = *input.add(i);
        if value != 48 && value != 49 { return -1; }
    }
    if length > capacity || output.is_null() { return -2; }
    for i in 0..length {
        *output.add(i) = if *input.add(i) == 48 { 49 } else { 48 };
    }
    length as i64
}
