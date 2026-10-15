/// Recursive four-neighbor DFS with a visited set and backtracking.
const MAX_CELLS: usize = 36;
const MAX_WORD_LENGTH: usize = 15;

fn is_letter(value: i64) -> bool {
    (value >= b'A' as i64 && value <= b'Z' as i64) ||
        (value >= b'a' as i64 && value <= b'z' as i64)
}

unsafe fn visit(input: *const i64, columns: usize, rows: usize, word_start: usize,
    word_length: usize, position: usize, word_index: usize, visited: *mut bool) -> bool {
    if *visited.add(position) || *input.add(2 + position) != *input.add(word_start + word_index) {
        return false;
    }
    *visited.add(position) = true;
    if word_index + 1 == word_length {
        *visited.add(position) = false;
        return true;
    }
    let row = position / columns;
    let column = position % columns;
    let found = (row > 0 && visit(input, columns, rows, word_start, word_length,
                                  position - columns, word_index + 1, visited)) ||
                (row + 1 < rows && visit(input, columns, rows, word_start, word_length,
                                         position + columns, word_index + 1, visited)) ||
                (column > 0 && visit(input, columns, rows, word_start, word_length,
                                     position - 1, word_index + 1, visited)) ||
                (column + 1 < columns && visit(input, columns, rows, word_start, word_length,
                                               position + 1, word_index + 1, visited));
    *visited.add(position) = false;
    found
}

#[no_mangle]
pub unsafe extern "C" fn word_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 5 { return -1; }
    let rows_value = *input;
    let columns_value = *input.add(1);
    if rows_value < 1 || rows_value > 6 || columns_value < 1 || columns_value > 6 { return -1; }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    let cells = rows * columns;
    let word_length_index = 2 + cells;
    if length <= word_length_index { return -1; }
    let word_length_value = *input.add(word_length_index);
    if word_length_value < 1 || word_length_value > MAX_WORD_LENGTH as i64 ||
        length != word_length_index + 1 + word_length_value as usize { return -1; }
    let word_length = word_length_value as usize;
    for index in 0..cells {
        if !is_letter(*input.add(2 + index)) { return -1; }
    }
    let word_start = word_length_index + 1;
    for index in 0..word_length {
        if !is_letter(*input.add(word_start + index)) { return -1; }
    }
    if word_length > cells { return 0; }
    let mut visited = [false; MAX_CELLS];
    for position in 0..cells {
        if visit(input, columns, rows, word_start, word_length, position, 0, visited.as_mut_ptr()) {
            return 1;
        }
    }
    0
}
