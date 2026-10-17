/// Bounded half-open worker search returning its found flag.
#[no_mangle]
pub unsafe extern "C" fn linear_search_thread(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > 69 { return -1; }
    let count_arg = *input;
    let left = *input.add(1);
    let right = *input.add(2);
    let target = *input.add(3);
    if !(1..=64).contains(&count_arg) || length != count_arg as usize + 4 { return -1; }
    if left < 0 || left > right || right > count_arg
        || target < i32::MIN as i64 || target > i32::MAX as i64 { return -1; }
    let count = count_arg as usize;
    for index in 0..count {
        let value = *input.add(index + 4);
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
    }
    for index in left as usize..right as usize {
        if *input.add(index + 4) == target { return 1; }
    }
    0
}
