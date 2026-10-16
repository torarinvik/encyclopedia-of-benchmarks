const MAX_WORDS = 8;
const MAX_WORD_LENGTH = 8;

fn search(grid: *[64]i64, rows: usize, cols: usize,
    words: *[MAX_WORDS][MAX_WORD_LENGTH]i64, lengths: *[MAX_WORDS]usize,
    order: *[MAX_WORDS]usize, depth: usize, word_count: usize) bool {
    if (depth == word_count) return true;
    const word = order[depth];
    const word_length = lengths[word];
    for (0..rows) |row| {
        for (0..cols) |col| {
            for (0..2) |direction| {
                const vertical = direction == 0;
                if ((vertical and row + word_length > rows) or (!vertical and col + word_length > cols)) continue;
                var cells: [MAX_WORD_LENGTH]usize = @splat(0);
                var added: [MAX_WORD_LENGTH]bool = @splat(false);
                var valid = true;
                for (0..word_length) |i| {
                    const cell = if (vertical) (row + i) * cols + col else row * cols + col + i;
                    cells[i] = cell;
                    if (grid[cell] != 0 and grid[cell] != words[word][i]) valid = false;
                }
                if (!valid) continue;
                for (0..word_length) |i| {
                    added[i] = grid[cells[i]] == 0;
                    grid[cells[i]] = words[word][i];
                }
                if (search(grid, rows, cols, words, lengths, order, depth + 1, word_count)) return true;
                for (0..word_length) |i| {
                    if (added[i]) grid[cells[i]] = 0;
                }
            }
        }
    }
    return false;
}

fn putI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn crossword_puzzle_solver(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3) return -1;
    const values = input.?;
    const rows_value = values[0];
    const cols_value = values[1];
    const count_value = values[2];
    if (rows_value < 1 or rows_value > 8 or cols_value < 1 or cols_value > 8 or count_value < 0 or count_value > 8) return -1;
    const rows: usize = @intCast(rows_value);
    const cols: usize = @intCast(cols_value);
    const word_count: usize = @intCast(count_value);
    if (length < 3 + rows * cols) return -1;
    var grid: [64]i64 = @splat(0);
    for (0..rows * cols) |i| {
        const value = values[3 + i];
        if (value != 0 and value != -1 and (value < 65 or value > 90)) return -1;
        grid[i] = value;
    }
    var words: [MAX_WORDS][MAX_WORD_LENGTH]i64 = @splat(@splat(0));
    var lengths: [MAX_WORDS]usize = @splat(0);
    var position: usize = 3 + rows * cols;
    for (0..word_count) |word| {
        if (position >= length or values[position] < 1 or values[position] > MAX_WORD_LENGTH) return -1;
        lengths[word] = @intCast(values[position]);
        position += 1;
        if (lengths[word] > length - position) return -1;
        for (0..lengths[word]) |i| {
            const letter = values[position];
            if (letter < 65 or letter > 90) return -1;
            words[word][i] = letter;
            position += 1;
        }
    }
    if (position != length) return -1;
    var order: [MAX_WORDS]usize = @splat(0);
    for (0..word_count) |i| order[i] = i;
    for (1..word_count) |i| {
        const value = order[i];
        var j = i;
        while (j > 0 and lengths[order[j - 1]] < lengths[value]) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = value;
    }
    const solved = search(&grid, rows, cols, &words, &lengths, &order, 0, word_count);
    const required = (1 + rows * cols) * 8;
    if (output == null or capacity < required) return -2;
    const out = output.?;
    putI64(out, 0, if (solved) 1 else 0);
    for (0..rows * cols) |i| putI64(out, (i + 1) * 8, grid[i]);
    return @intCast(required);
}
