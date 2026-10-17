const MAX_N: usize = 8;
const MAX_INPUT_WORDS: usize = 1 + MAX_N * MAX_N;
const MAX_OUTPUT_BYTES: usize = 4 * (1 + MAX_N * MAX_N);

fn searchPath(input: [*]const i32, path: *[MAX_N * MAX_N]i32, n: usize, row: usize, col: usize) bool {
    const index = row * n + col;
    path[index] = 1;
    if (row == n - 1 and col == n - 1) return true;
    if (col + 1 < n and input[1 + index + 1] == 1 and searchPath(input, path, n, row, col + 1)) return true;
    if (row + 1 < n and input[1 + index + n] == 1 and searchPath(input, path, n, row + 1, col)) return true;
    path[index] = 0;
    return false;
}

fn putI32Le(output: []u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn rat_maze(input_opt: ?[*]const i32, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_WORDS) return -1;
    const input = input_opt.?;
    const n_raw = input[0];
    if (n_raw < 1 or n_raw > @as(i32, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(n_raw);
    const cells = n * n;
    if (length != 1 + cells or input[1] != 1) return -1;
    for (0..cells) |i| if (input[1 + i] < 0 or input[1 + i] > 1) return -1;
    var path: [MAX_N * MAX_N]i32 = [_]i32{0} ** (MAX_N * MAX_N);
    const found = searchPath(input, &path, n, 0, 0);
    const word_count = if (found) 1 + cells else 1;
    const bytes = word_count * 4;
    if (output_opt == null or capacity < bytes) return -2;
    var buffer: [MAX_OUTPUT_BYTES]u8 = undefined;
    putI32Le(&buffer, 0, if (found) 1 else 0);
    if (found) for (0..cells) |i| putI32Le(&buffer, (i + 1) * 4, path[i]);
    const output = output_opt.?;
    for (0..bytes) |i| output[i] = buffer[i];
    return @intCast(bytes);
}
