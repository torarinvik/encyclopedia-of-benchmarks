/// Count transitions from ASCII space to a non-space byte.
const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn count_segments(input: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && input.is_null()) { return -1; }
    if length == 0 { return 0; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let mut count = 0_i64;
    let mut previous_was_space = true;
    for &value in values {
        if !(1..=127).contains(&value) { return -1; }
        if value != 32 && previous_was_space { count += 1; }
        previous_was_space = value == 32;
    }
    count
}
