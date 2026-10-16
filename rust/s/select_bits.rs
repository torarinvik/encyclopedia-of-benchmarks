#[no_mangle]
pub extern "C" fn select_bits(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(1..=3).contains(&length) {
        return -1;
    }

    let number = unsafe { *values };
    if !(0..=9_007_199_254_740_991).contains(&number) {
        return -1;
    }

    let first = if length >= 2 {
        unsafe { *values.add(1) }
    } else {
        1
    };
    let last = if length >= 3 {
        unsafe { *values.add(2) }
    } else {
        53
    };
    if !(1..=53).contains(&first) || !(1..=53).contains(&last) {
        return -1;
    }

    let modulus = 1_i64 << last as u32;
    (number % modulus) >> (first - 1) as u32
}
