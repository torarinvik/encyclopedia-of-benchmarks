/// Count all palindromic substrings by expanding around odd and even centers.
#[no_mangle]
pub extern "C" fn palindromic_substrings(values: *const i64, length: usize) -> i64 {
    if length == 0 || length > 1000 || values.is_null() { return -1; }
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if !(97..=122).contains(&value) { return -1; }
    }

    let mut count = 0i64;
    for center in 0..length {
        count += 1;
        let mut left = center;
        let mut right = center;
        while left > 0 && right + 1 < length &&
            unsafe { *values.add(left - 1) == *values.add(right + 1) } {
            count += 1;
            left -= 1;
            right += 1;
        }

        left = center;
        right = center + 1;
        while right < length && unsafe { *values.add(left) == *values.add(right) } {
            count += 1;
            if left == 0 || right + 1 == length { break; }
            left -= 1;
            right += 1;
        }
    }
    count
}
