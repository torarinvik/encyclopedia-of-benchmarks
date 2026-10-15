#[no_mangle]
pub unsafe extern "C" fn validate_sudoku_board(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length != 81 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values.iter().any(|&value| value != b'.' as i64 && !(b'1' as i64..=b'9' as i64).contains(&value)) { return -1; }
    if output.is_null() || capacity < 1 { return -2; }
    let (mut rows, mut columns, mut boxes) = ([0_u16; 9], [0_u16; 9], [0_u16; 9]);
    let mut valid = true;
    for (i, &value) in values.iter().enumerate() {
        if value == b'.' as i64 { continue; }
        let row = i / 9; let col = i % 9; let bx = (row / 3) * 3 + col / 3;
        let bit = 1_u16 << (value as u8 - b'0');
        if rows[row] & bit != 0 || columns[col] & bit != 0 || boxes[bx] & bit != 0 { valid = false; }
        rows[row] |= bit; columns[col] |= bit; boxes[bx] |= bit;
    }
    *output = u8::from(valid);
    1
}
