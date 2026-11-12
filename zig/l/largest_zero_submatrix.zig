const MAX_ROWS: usize = 16;
const MAX_COLUMNS: usize = 16;

fn solve(input: []const i64) i64 {
    if (input.len < 2 or input.len > 259) return -1;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_ROWS)) or
        input[1] < 1 or input[1] > @as(i64, @intCast(MAX_COLUMNS))) return -1;
    const rows: usize = @intCast(input[0]);
    const columns: usize = @intCast(input[1]);
    if (input.len != 2 + rows * columns) return -1;
    for (input[2..]) |cell| if (cell != 0 and cell != 1) return -1;

    var last_one: [MAX_COLUMNS]i64 = @splat(-1);
    var left: [MAX_COLUMNS]i64 = @splat(0);
    var right: [MAX_COLUMNS]i64 = @splat(0);
    var stack: [MAX_COLUMNS]usize = @splat(0);
    var best: i64 = 0;
    for (0..rows) |row| {
        for (0..columns) |column| {
            if (input[2 + row * columns + column] == 1) last_one[column] = @intCast(row);
        }
        var top: usize = 0;
        for (0..columns) |column| {
            while (top > 0 and last_one[stack[top - 1]] <= last_one[column]) top -= 1;
            left[column] = if (top == 0) -1 else @intCast(stack[top - 1]);
            stack[top] = column;
            top += 1;
        }
        top = 0;
        var cursor = columns;
        while (cursor > 0) {
            const column = cursor - 1;
            while (top > 0 and last_one[stack[top - 1]] <= last_one[column]) top -= 1;
            right[column] = if (top == 0) @intCast(columns) else @intCast(stack[top - 1]);
            stack[top] = column;
            top += 1;
            cursor -= 1;
        }
        for (0..columns) |column| {
            const height: i64 = @as(i64, @intCast(row)) - last_one[column];
            const width = right[column] - left[column] - 1;
            best = @max(best, height * width);
        }
    }
    return best;
}

export fn largest_zero_submatrix(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 259) return -1;
    return solve(input_opt.?[0..length]);
}
