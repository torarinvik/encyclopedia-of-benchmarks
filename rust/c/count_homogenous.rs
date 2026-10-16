/// Count contiguous runs of equal ASCII bytes.
#[no_mangle]
pub extern "C" fn count_homogenous(input: *const i64, length: usize) -> i64 {
    const MAX_TEXT_BYTES: usize = 4096;
    if input.is_null() || length < 1 {
        return -1;
    }
    let count_value = unsafe { *input };
    if !(0..=MAX_TEXT_BYTES as i64).contains(&count_value) {
        return -1;
    }
    let count = count_value as usize;
    if length != count + 1 {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[1..].iter().any(|&byte| !(0..=127).contains(&byte)) {
        return -1;
    }
    if count == 0 {
        return 0;
    }
    let mut runs = 1i64;
    for index in 2..=count {
        if input[index] != input[index - 1] {
            runs += 1;
        }
    }
    runs
}
