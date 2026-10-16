/// Check full rows, columns, and diagonals for one square-board player.
pub export fn n_in_a_row_board_status(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 258 or values[0] < 2 or values[0] > 16
        or (values[1] != 1 and values[1] != 2)) return -1;
    const size: usize = @intCast(values[0]);
    const player = values[1];
    if (length != 2 + size * size) return -1;
    for (0..size * size) |index| {
        if (values[2 + index] < 0 or values[2 + index] > 2) return -1;
    }
    var has_empty = false;
    for (0..size) |row| {
        var row_win = true;
        for (0..size) |column| {
            const cell = values[2 + row * size + column];
            if (cell == 0) has_empty = true;
            if (cell != player) row_win = false;
        }
        if (row_win) return 1;
    }
    for (0..size) |column| {
        var column_win = true;
        for (0..size) |row| {
            if (values[2 + row * size + column] != player) column_win = false;
        }
        if (column_win) return 1;
    }
    var main_diagonal_win = true;
    var anti_diagonal_win = true;
    for (0..size) |index| {
        if (values[2 + index * size + index] != player) main_diagonal_win = false;
        if (values[2 + index * size + size - 1 - index] != player) anti_diagonal_win = false;
    }
    if (main_diagonal_win or anti_diagonal_win) return 1;
    return if (has_empty) 0 else 2;
}
