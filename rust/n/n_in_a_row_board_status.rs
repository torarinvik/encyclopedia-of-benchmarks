/// Check full rows, columns, and diagonals for one square-board player.
#[no_mangle]
pub extern "C" fn n_in_a_row_board_status(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 258 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if !(2..=16).contains(&values[0]) || !(values[1] == 1 || values[1] == 2) {
        return -1;
    }
    let size = values[0] as usize;
    let player = values[1];
    if length != 2 + size * size || values[2..].iter().any(|cell| !(0..=2).contains(cell)) {
        return -1;
    }
    let mut has_empty = false;
    for row in 0..size {
        let mut row_win = true;
        for column in 0..size {
            let cell = values[2 + row * size + column];
            has_empty |= cell == 0;
            row_win &= cell == player;
        }
        if row_win {
            return 1;
        }
    }
    for column in 0..size {
        let mut column_win = true;
        for row in 0..size {
            column_win &= values[2 + row * size + column] == player;
        }
        if column_win {
            return 1;
        }
    }
    let mut main_diagonal_win = true;
    let mut anti_diagonal_win = true;
    for index in 0..size {
        main_diagonal_win &= values[2 + index * size + index] == player;
        anti_diagonal_win &= values[2 + index * size + size - 1 - index] == player;
    }
    if main_diagonal_win || anti_diagonal_win {
        return 1;
    }
    if has_empty { 0 } else { 2 }
}
