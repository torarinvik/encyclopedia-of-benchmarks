const MAX_DIMENSION: usize = 4;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const MAX_PATH_LENGTH: usize = MAX_CELLS - 1;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 19;
const MAX_OUTPUT_WORDS: usize = 2097;
const MAX_OUTPUT_BYTES: usize = MAX_OUTPUT_WORDS * 8;

const Move = struct { row: isize, col: isize, code: i64 };
const Maze = struct {
    variant: usize,
    size: usize,
    cells: [MAX_CELLS]i64,
};
const Paths = struct {
    words: [MAX_OUTPUT_WORDS]i64,
    word_count: usize,
    count: usize,
};

fn movement(variant: usize, index: usize) Move {
    if (variant == 0) {
        return switch (index) {
            0 => .{ .row = 1, .col = 0, .code = 0 },
            1 => .{ .row = 0, .col = -1, .code = 1 },
            2 => .{ .row = 0, .col = 1, .code = 2 },
            else => .{ .row = -1, .col = 0, .code = 3 },
        };
    }
    return switch (index) {
        0 => .{ .row = 0, .col = 1, .code = 2 },
        1 => .{ .row = 1, .col = 0, .code = 0 },
        2 => .{ .row = -1, .col = 0, .code = 3 },
        else => .{ .row = 0, .col = -1, .code = 1 },
    };
}

fn parseMaze(values: [*]const i64, length: usize) ?Maze {
    if (length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return null;
    if (values[0] != 0 and values[0] != 1) return null;
    if (values[1] < 1 or values[1] > MAX_DIMENSION) return null;
    const size: usize = @intCast(values[1]);
    const cell_count = size * size;
    if (length != 2 + cell_count) return null;

    var maze = Maze{
        .variant = @intCast(values[0]),
        .size = size,
        .cells = [_]i64{0} ** MAX_CELLS,
    };
    for (0..cell_count) |index| {
        const cell = values[2 + index];
        if (cell != 0 and cell != 1) return null;
        maze.cells[index] = cell;
    }
    return maze;
}

fn collectPaths(
    maze: *const Maze,
    row: isize,
    col: isize,
    visited: *[MAX_CELLS]bool,
    current: *[MAX_PATH_LENGTH]u8,
    path_length: usize,
    paths: *Paths,
) bool {
    if (row == @as(isize, @intCast(maze.size - 1)) and col == @as(isize, @intCast(maze.size - 1))) {
        paths.words[paths.word_count] = @intCast(path_length);
        paths.word_count += 1;
        for (0..path_length) |index| {
            paths.words[paths.word_count] = @intCast(current[index]);
            paths.word_count += 1;
        }
        paths.count += 1;
        paths.words[0] = @intCast(paths.count);
        return maze.variant == 1;
    }

    const index = @as(usize, @intCast(row)) * maze.size + @as(usize, @intCast(col));
    visited[index] = true;
    for (0..4) |move_index| {
        const delta = movement(maze.variant, move_index);
        const next_row = row + delta.row;
        const next_col = col + delta.col;
        if (next_row < 0 or next_col < 0 or next_row >= @as(isize, @intCast(maze.size)) or
            next_col >= @as(isize, @intCast(maze.size))) continue;
        const next_index = @as(usize, @intCast(next_row)) * maze.size + @as(usize, @intCast(next_col));
        if (maze.cells[next_index] != 1 or visited[next_index]) continue;
        current[path_length] = @intCast(delta.code);
        if (collectPaths(maze, next_row, next_col, visited, current, path_length + 1, paths)) {
            visited[index] = false;
            return true;
        }
    }
    visited[index] = false;
    return false;
}

export fn rat_in_amaze(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    const values = input orelse return -1;
    const maze = parseMaze(values, input_length) orelse return -1;
    var paths = Paths{
        .words = [_]i64{0} ** MAX_OUTPUT_WORDS,
        .word_count = 1,
        .count = 0,
    };
    if (maze.cells[0] == 1 and maze.cells[maze.size * maze.size - 1] == 1) {
        var visited = [_]bool{false} ** MAX_CELLS;
        var current = [_]u8{0} ** MAX_PATH_LENGTH;
        _ = collectPaths(&maze, 0, 0, &visited, &current, 0, &paths);
    }
    if (paths.count == 0) return -3;

    const output_bytes = paths.word_count * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    const out = output orelse return -2;
    if (output_capacity < output_bytes) return -2;
    for (0..paths.word_count) |index| {
        const bits: u64 = @bitCast(paths.words[index]);
        for (0..8) |byte| {
            const shift: u6 = @intCast(byte * 8);
            out[index * 8 + byte] = @truncate(bits >> shift);
        }
    }
    return @intCast(output_bytes);
}
