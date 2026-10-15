#[no_mangle]
pub extern "C" fn fibonacci_matrix(index: i64) -> i64 {
    if !(0..=92).contains(&index) { return -1; }
    if index == 0 { return 0; }
    let mut r00 = 1i64;
    let mut r01 = 0i64;
    let mut r10 = 0i64;
    let mut r11 = 1i64;
    let mut b00 = 1i64;
    let mut b01 = 1i64;
    let mut b10 = 1i64;
    let mut b11 = 0i64;
    let mut exponent = index - 1;
    while exponent > 0 {
        if exponent % 2 == 1 {
            let n00 = r00 * b00 + r01 * b10;
            let n01 = r00 * b01 + r01 * b11;
            let n10 = r10 * b00 + r11 * b10;
            let n11 = r10 * b01 + r11 * b11;
            r00 = n00; r01 = n01; r10 = n10; r11 = n11;
            exponent -= 1;
        } else {
            let n00 = b00 * b00 + b01 * b10;
            let n01 = b00 * b01 + b01 * b11;
            let n10 = b10 * b00 + b11 * b10;
            let n11 = b10 * b01 + b11 * b11;
            b00 = n00; b01 = n01; b10 = n10; b11 = n11;
            exponent /= 2;
        }
    }
    r00
}
