/// Copy positive list values, then scan each mirrored twin pair.
const MAX_LENGTH: usize = 1024;

#[no_mangle]
pub extern "C" fn maximum_twin_sum_of_linked_list(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_LENGTH || length % 2 != 0 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let mut copied = [0i32; MAX_LENGTH];
    for (index, &value) in input.iter().enumerate() {
        if !(1..=100000).contains(&value) { return -1; }
        copied[index] = value as i32;
    }
    let mut maximum = 0i64;
    for index in 0..length / 2 {
        let twin_sum = i64::from(copied[index]) + i64::from(copied[length - index - 1]);
        if twin_sum > maximum { maximum = twin_sum; }
    }
    maximum
}
