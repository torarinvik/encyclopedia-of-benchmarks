const MAX_DIMENSION: usize = 32;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const MAX_WORDS: usize = 96;
const MAX_WORD_LENGTH: usize = 32;
const MAX_INPUT_VALUES: usize = 4096;
const RNG_MODULUS: u64 = 2147483647;

fn nextRandom(state: *u64) u64 {
    state.* = (state.* * 48271) % RNG_MODULUS;
    return state.*;
}

fn shuffle(items: []usize, state: *u64) void {
    var remaining = items.len;
    while (remaining > 1) {
        const other: usize = @intCast(nextRandom(state) % remaining);
        const temporary = items[remaining - 1];
        items[remaining - 1] = items[other];
        items[other] = temporary;
        remaining -= 1;
    }
}

fn isAsciiLetter(value: i64) bool {
    return (value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z');
}

export fn word_search_generator(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 4 or length > MAX_INPUT_VALUES) return -1;
    const width_value = values[0];
    const height_value = values[1];
    const seed_value = values[2];
    const word_count_value = values[3];
    if (width_value < 1 or width_value > @as(i64, @intCast(MAX_DIMENSION)) or
        height_value < 1 or height_value > @as(i64, @intCast(MAX_DIMENSION)) or
        seed_value < 1 or seed_value >= @as(i64, @intCast(RNG_MODULUS)) or
        word_count_value < 0 or word_count_value > @as(i64, @intCast(MAX_WORDS))) return -1;
    const width: usize = @intCast(width_value);
    const height: usize = @intCast(height_value);
    const word_count: usize = @intCast(word_count_value);

    var position: usize = 4;
    for (0..word_count) |_| {
        if (position >= length) return -1;
        const word_length_value = values[position];
        position += 1;
        if (word_length_value < 1 or word_length_value > @as(i64, @intCast(MAX_WORD_LENGTH)) or
            word_length_value > @as(i64, @intCast(length - position))) return -1;
        const word_length: usize = @intCast(word_length_value);
        for (0..word_length) |offset| {
            if (!isAsciiLetter(values[position + offset])) return -1;
        }
        position += word_length;
    }
    if (position != length) return -1;

    const cells = width * height;
    if (output == null or output_capacity < cells) return -2;
    var board: [MAX_CELLS]u8 = @splat(0);
    const row_delta = [_]i32{-1, -1, 0, 1, 1, 1, 0, -1};
    const column_delta = [_]i32{0, 1, 1, 1, 0, -1, -1, -1};
    var state: u64 = @intCast(seed_value);
    position = 4;

    for (0..word_count) |_| {
        const word_length: usize = @intCast(values[position]);
        position += 1;
        const word_start = position;
        position += word_length;
        var rows: [MAX_DIMENSION]usize = undefined;
        var columns: [MAX_DIMENSION]usize = undefined;
        for (0..height) |row| rows[row] = row;
        for (0..width) |column| columns[column] = column;
        shuffle(rows[0..height], &state);
        shuffle(columns[0..width], &state);
        const direction: usize = @intCast(nextRandom(&state) % 8);
        var placed = false;

        for (rows[0..height]) |row| {
            for (columns[0..width]) |column| {
                const last_row = @as(i32, @intCast(row)) +
                    (@as(i32, @intCast(word_length)) - 1) * row_delta[direction];
                const last_column = @as(i32, @intCast(column)) +
                    (@as(i32, @intCast(word_length)) - 1) * column_delta[direction];
                if (last_row < 0 or last_row >= @as(i32, @intCast(height)) or
                    last_column < 0 or last_column >= @as(i32, @intCast(width))) continue;
                var available = true;
                for (0..word_length) |offset| {
                    const current_row = @as(i32, @intCast(row)) +
                        @as(i32, @intCast(offset)) * row_delta[direction];
                    const current_column = @as(i32, @intCast(column)) +
                        @as(i32, @intCast(offset)) * column_delta[direction];
                    const cell: usize = @intCast(current_row * @as(i32, @intCast(width)) + current_column);
                    if (board[cell] != 0) {
                        available = false;
                        break;
                    }
                }
                if (!available) continue;
                for (0..word_length) |offset| {
                    const current_row = @as(i32, @intCast(row)) +
                        @as(i32, @intCast(offset)) * row_delta[direction];
                    const current_column = @as(i32, @intCast(column)) +
                        @as(i32, @intCast(offset)) * column_delta[direction];
                    const cell: usize = @intCast(current_row * @as(i32, @intCast(width)) + current_column);
                    board[cell] = @intCast(values[word_start + offset]);
                }
                placed = true;
                break;
            }
            if (placed) break;
        }
    }
    for (0..cells) |index| output[index] = board[index];
    return @intCast(cells);
}
