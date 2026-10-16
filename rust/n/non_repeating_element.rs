const MAX_VALUE: i64 = 1_073_741_823;

#[no_mangle]
pub extern "C" fn non_repeating_element(values: *const i64, length: usize) -> i64 {
    if !(2..=64).contains(&length) || length % 2 != 0 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values.iter().any(|&value| !(0..=MAX_VALUE).contains(&value)) {
        return -1;
    }
    let mut xor_result = 0i32;
    for &value in values {
        xor_result ^= value as i32;
    }
    let rightmost_set_bit = xor_result & -xor_result;
    let (mut num1, mut num2) = (0i32, 0i32);
    for &item in values {
        let value = item as i32;
        if value & rightmost_set_bit != 0 {
            num1 ^= value;
        } else {
            num2 ^= value;
        }
    }
    ((num1 as i64) << 32) | (num2 as u32 as i64)
}
