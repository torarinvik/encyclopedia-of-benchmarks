#[no_mangle]
pub unsafe extern "C" fn decimal_to_hex(mut value: i64, output: *mut u8, capacity: usize) -> i64 {
    if !(0..=9_007_199_254_740_991).contains(&value) { return -1; }
    let mut width = 1usize;
    let mut n = value;
    while n >= 16 { width += 1; n /= 16; }
    if output.is_null() || capacity < width { return -2; }
    let out = std::slice::from_raw_parts_mut(output, width);
    let mut position = width;
    loop {
        let digit = value % 16;
        position -= 1;
        out[position] = if digit < 10 { b'0' + digit as u8 } else { b'A' + (digit - 10) as u8 };
        value /= 16;
        if position == 0 { break; }
    }
    width as i64
}
