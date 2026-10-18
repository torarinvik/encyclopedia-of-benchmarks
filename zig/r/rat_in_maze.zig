const MAX_DIMENSION: usize = 8;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 71;
const MAX_OUTPUT_BYTES: usize = MAX_CELLS * 8;

const Maze = struct {
    variant: usize,
    rows: usize,
    cols: usize,
    start_row: usize,
    start_col: usize,
    destination_row: usize,
    destination_col: usize,
    cells: [MAX_CELLS]i64,
};

fn parseMaze(values: [*]const i64, length: usize) ?Maze {
    if (length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return null;
    var maze = Maze{
        .variant = 0,
        .rows = 0,
        .cols = 0,
        .start_row = 0,
        .start_col = 0,
        .destination_row = 0,
        .destination_col = 0,
        .cells = [_]i64{0} ** MAX_CELLS,
    };

    if (values[0] == 0) {
        if (length < 7 or values[1] < 1 or values[1] > MAX_DIMENSION) return null;
        const size: usize = @intCast(values[1]);
        if (length != 6 + size * size) return null;
        for (2..6) |index| {
            if (values[index] < 0 or values[index] >= @as(i64, @intCast(size))) return null;
        }
        maze.variant = 0;
        maze.rows = size;
        maze.cols = size;
        maze.start_row = @intCast(values[2]);
        maze.start_col = @intCast(values[3]);
        maze.destination_row = @intCast(values[4]);
        maze.destination_col = @intCast(values[5]);
        for (0..size * size) |index| {
            const cell = values[6 + index];
            if (cell != 0 and cell != 1) return null;
            maze.cells[index] = cell;
        }
    } else if (values[0] == 1) {
        if (length < 6 or values[1] < 1 or values[1] > MAX_DIMENSION or
            values[2] < 1 or values[2] > MAX_DIMENSION) return null;
        const rows: usize = @intCast(values[1]);
        const cols: usize = @intCast(values[2]);
        if (length != 5 + rows * cols || values[3] < 0 or values[3] >= @as(i64, @intCast(rows)) or
            values[4] < 0 or values[4] >= @as(i64, @intCast(cols))) return null;
        maze.variant = 1;
        maze.rows = rows;
        maze.cols = cols;
        maze.start_row = @intCast(values[3]);
        maze.start_col = @intCast(values[4]);
        maze.destination_row = rows - 1;
        maze.destination_col = cols - 1;
        for (0..rows * cols) |index| {
            const cell = values[5 + index];
            if (cell != 0 and cell != 1) return null;
            maze.cells[index] = cell;
        }
    } else return null;
    return maze;
}

fn searchPath(maze: *const Maze, row: isize, col: isize, path: *[MAX_CELLS]bool) bool {
    if (maze.variant == 1 and row == @as(isize, @intCast(maze.destination_row)) and
        col == @as(isize, @intCast(maze.destination_col))) {
        path[@as(usize, @intCast(row)) * maze.cols + @as(usize, @intCast(col))] = true;
        return true;
    }
    if (row < 0 or col < 0 or row >= @as(isize, @intCast(maze.rows)) or
        col >= @as(isize, @intCast(maze.cols))) return false;
    const index = @as(usize, @intCast(row)) * maze.cols + @as(usize, @intCast(col));
    const open_value: i64 = if (maze.variant == 0) 0 else 1;
    if (maze.cells[index] != open_value or path[index]) return false;
    path[index] = true;
    if (maze.variant == 0 and row == @as(isize, @intCast(maze.destination_row)) and
        col == @as(isize, @intCast(maze.destination_col))) return true;

    const directions = if (maze.variant == 0)
        [4][2]isize{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 } }
    else
        [4][2]isize{ .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 }, .{ -1, 0 } };
    for (directions) |direction| {
        if (searchPath(maze, row + direction[0], col + direction[1], path)) return true;
    }
    path[index] = false;
    return false;
}

export fn rat_in_maze(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    const values = input orelse return -1;
    const maze = parseMaze(values, input_length) orelse return -1;
    var path = [_]bool{false} ** MAX_CELLS;
    if (!searchPath(&maze, @intCast(maze.start_row), @intCast(maze.start_col), &path)) return -3;

    const cells = maze.rows * maze.cols;
    const output_bytes = cells * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    const out = output orelse return -2;
    if (output_capacity < output_bytes) return -2;
    for (0..cells) |index| {
        const value: i64 = if (maze.variant == 0) (if (path[index]) 0 else 1) else (if (path[index]) 1 else 0);
        const bits: u64 = @bitCast(value);
        for (0..8) |byte| {
            const shift: u6 = @intCast(byte * 8);
            out[index * 8 + byte] = @truncate(bits >> shift);
        }
    }
    return @intCast(output_bytes);
}
