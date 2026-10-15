/// Recursive four-neighbor DFS with a visited set and backtracking.
const MAX_CELLS: usize = 36;
const MAX_WORD_LENGTH: usize = 15;

fn isLetter(value: i64) bool {
    return (value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z');
}

fn visit(input: [*]const i64, columns: usize, rows: usize, word_start: usize,
    word_length: usize, position: usize, word_index: usize, visited: [*]bool) bool {
    if (visited[position] or input[2 + position] != input[word_start + word_index]) return false;
    visited[position] = true;
    if (word_index + 1 == word_length) {
        visited[position] = false;
        return true;
    }
    const row = position / columns;
    const column = position % columns;
    const found = (row > 0 and visit(input, columns, rows, word_start, word_length,
                                     position - columns, word_index + 1, visited)) or
                  (row + 1 < rows and visit(input, columns, rows, word_start, word_length,
                                            position + columns, word_index + 1, visited)) or
                  (column > 0 and visit(input, columns, rows, word_start, word_length,
                                       position - 1, word_index + 1, visited)) or
                  (column + 1 < columns and visit(input, columns, rows, word_start, word_length,
                                                  position + 1, word_index + 1, visited));
    visited[position] = false;
    return found;
}

export fn word_search(input: [*]const i64, length: usize) i64 {
    if (length < 5) return -1;
    if (input[0] < 1 or input[0] > 6 or input[1] < 1 or input[1] > 6) return -1;
    const rows: usize = @intCast(input[0]);
    const columns: usize = @intCast(input[1]);
    const cells = rows * columns;
    const word_length_index = 2 + cells;
    if (length <= word_length_index) return -1;
    const word_length_value = input[word_length_index];
    if (word_length_value < 1 or word_length_value > MAX_WORD_LENGTH or
        length != word_length_index + 1 + @as(usize, @intCast(word_length_value))) return -1;
    const word_length: usize = @intCast(word_length_value);
    for (0..cells) |index| {
        if (!isLetter(input[2 + index])) return -1;
    }
    const word_start = word_length_index + 1;
    for (0..word_length) |index| {
        if (!isLetter(input[word_start + index])) return -1;
    }
    if (word_length > cells) return 0;
    var visited: [MAX_CELLS]bool = @splat(false);
    for (0..cells) |position| {
        if (visit(input, columns, rows, word_start, word_length, position, 0,
            @ptrCast(&visited[0]))) return 1;
    }
    return 0;
}
