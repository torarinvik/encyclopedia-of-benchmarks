/// Row-major backtracking Sudoku solver with row, column, and box masks.

fn search_sudoku(board: &mut [i64; 81], rows: &mut [u16; 9], columns: &mut [u16; 9],
                 boxes: &mut [u16; 9], position: usize) -> bool {
    let mut current = position;
    while current < 81 && board[current] != 0 { current += 1; }
    if current == 81 { return true; }
    let row = current / 9;
    let column = current % 9;
    let box_index = (row / 3) * 3 + column / 3;
    for digit in 1..=9 {
        let bit = 1u16 << digit;
        if rows[row] & bit != 0 || columns[column] & bit != 0 || boxes[box_index] & bit != 0 { continue; }
        board[current] = digit as i64;
        rows[row] |= bit; columns[column] |= bit; boxes[box_index] |= bit;
        if search_sudoku(board, rows, columns, boxes, current + 1) { return true; }
        board[current] = 0;
        rows[row] ^= bit; columns[column] ^= bit; boxes[box_index] ^= bit;
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn sudoku_solver(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length != 81 || values.is_null() { return -1; }
    let mut board = [0i64; 81];
    let mut rows = [0u16; 9];
    let mut columns = [0u16; 9];
    let mut boxes = [0u16; 9];
    for position in 0..81 {
        let digit = *values.add(position);
        if !(0..=9).contains(&digit) { return -1; }
        board[position] = digit;
        if digit == 0 { continue; }
        let row = position / 9;
        let column = position % 9;
        let box_index = (row / 3) * 3 + column / 3;
        let bit = 1u16 << digit;
        if rows[row] & bit != 0 || columns[column] & bit != 0 || boxes[box_index] & bit != 0 { return -1; }
        rows[row] |= bit; columns[column] |= bit; boxes[box_index] |= bit;
    }
    if output_capacity < 324 || output.is_null() { return -2; }
    if !search_sudoku(&mut board, &mut rows, &mut columns, &mut boxes, 0) { return -1; }
    for position in 0..81 {
        let digit = (board[position] as i32).to_le_bytes();
        for (byte, value) in digit.iter().enumerate() {
            *output.add(position * 4 + byte) = *value;
        }
    }
    81
}
