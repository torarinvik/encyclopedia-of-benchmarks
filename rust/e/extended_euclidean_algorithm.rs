/// Iterative extended Euclid for positive signed-32-bit inputs.
fn store_i32(value: i64, output: *mut u8, position: usize) -> usize {
    let magnitude = if value < 0 { (-value) as u64 } else { value as u64 };
    let mut bits = if value < 0 { (1u64 << 32) - magnitude } else { magnitude };
    for byte in 0..4 {
        unsafe { *output.add(position + byte) = (bits & 255) as u8; }
        bits >>= 8;
    }
    position + 4
}

#[no_mangle]
pub unsafe extern "C" fn extended_euclidean_algorithm(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize) -> i64 {
    if length != 2 { return -1; }
    let a = *input;
    let b = *input.add(1);
    if a < 1 || a > i32::MAX as i64 || b < 1 || b > i32::MAX as i64 { return -1; }
    if output_capacity < 12 { return -2; }

    let (mut old_r, mut remainder) = (a, b);
    let (mut old_x, mut x) = (1i64, 0i64);
    let (mut old_y, mut y) = (0i64, 1i64);
    while remainder != 0 {
        let quotient = old_r / remainder;
        let next_r = old_r - quotient * remainder;
        old_r = remainder;
        remainder = next_r;
        let next_x = old_x - quotient * x;
        old_x = x;
        x = next_x;
        let next_y = old_y - quotient * y;
        old_y = y;
        y = next_y;
    }
    if old_r > i32::MAX as i64 || old_x < i32::MIN as i64 || old_x > i32::MAX as i64 ||
        old_y < i32::MIN as i64 || old_y > i32::MAX as i64 { return -1; }
    let mut written = store_i32(old_r, output, 0);
    written = store_i32(old_x, output, written);
    written = store_i32(old_y, output, written);
    if written == 12 { 3 } else { -1 }
}
