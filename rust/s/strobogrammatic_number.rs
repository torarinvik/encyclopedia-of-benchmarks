const MAX_INPUT_LENGTH: usize = 64;

fn rotated_digit(value: i64) -> i64 {
    match value {
        48 => 48,
        49 => 49,
        54 => 57,
        56 => 56,
        57 => 54,
        _ => -1,
    }
}

#[no_mangle]
pub extern "C" fn strobogrammatic_number(bytes: *const i64, length: usize) -> i64 {
    if (bytes.is_null() && length != 0) || length > MAX_INPUT_LENGTH { return -1; }
    if length == 0 { return 1; }
    let values = unsafe { std::slice::from_raw_parts(bytes, length) };
    for &value in values {
        if !(0..=127).contains(&value) { return -1; }
    }
    let mut left = 0;
    let mut right = length;
    while left < right {
        right -= 1;
        if rotated_digit(values[left]) != values[right] { return 0; }
        left += 1;
    }
    1
}
