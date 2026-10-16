#[no_mangle]
pub unsafe extern "C" fn erosion_operation(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 38 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (height, width) = (values[0], values[1]);
    if !(1..=6).contains(&height) || !(1..=6).contains(&width) || length != 2 + (height * width) as usize { return -1; }
    if values[2..].iter().any(|&x| x != 0 && x != 1) { return -1; }
    let mut result = 0i64;
    for row in 0..height {
        for col in 0..width {
            let at = |r: i64, c: i64| values[2 + (r * width + c) as usize] == 1;
            if row > 0 && row + 1 < height && col > 0 && col + 1 < width
                && at(row, col) && at(row - 1, col) && at(row + 1, col) && at(row, col - 1) && at(row, col + 1) {
                result |= 1i64 << (row * width + col);
            }
        }
    }
    result
}
