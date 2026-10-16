const MAX_DIM: usize = 32;
const MAX_CELLS: usize = MAX_DIM * MAX_DIM;
const MAX_OUTPUT: usize = 8 + 8 * MAX_CELLS;

fn writeI64(payload: *[MAX_OUTPUT]u8, position: usize, value: i64) usize {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| payload[position + i] = @truncate(bits >> @intCast(8 * i));
    return position + 8;
}

export fn minesweeper(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 2 + MAX_CELLS) return -1;
    const rows_value, cols_value = .{ input[0], input[1] };
    if (rows_value < 1 or rows_value > @as(i64, @intCast(MAX_DIM)) or cols_value < 1 or cols_value > @as(i64, @intCast(MAX_DIM))) return -1;
    const rows: usize = @intCast(rows_value);
    const cols: usize = @intCast(cols_value);
    const count = rows * cols;
    if (length != 2 + count) return -1;
    var cells = [_]u8{0} ** MAX_CELLS;
    for (0..count) |i| {
        if (input[2 + i] != 0 and input[2 + i] != 1) return -1;
        cells[i] = @intCast(input[2 + i]);
    }
    var neighbors = [_]i64{0} ** MAX_CELLS;
    for (0..rows) |row| {
        for (0..cols) |col| {
            var mine_count: i64 = 0;
            var dr: i32 = -1;
            while (dr <= 1) : (dr += 1) {
                var dc: i32 = -1;
                while (dc <= 1) : (dc += 1) {
                    if (dr == 0 and dc == 0) continue;
                    const nr = @as(i32, @intCast(row)) + dr;
                    const nc = @as(i32, @intCast(col)) + dc;
                    if (nr >= 0 and nr < @as(i32, @intCast(rows)) and nc >= 0 and nc < @as(i32, @intCast(cols)) and cells[@as(usize, @intCast(nr)) * cols + @as(usize, @intCast(nc))] == 1) mine_count += 1;
                }
            }
            neighbors[row * cols + col] = mine_count;
        }
    }
    const needed = 8 + 8 * count;
    if (output == null or capacity < needed) return -2;
    var payload = [_]u8{0} ** MAX_OUTPUT;
    var written = writeI64(&payload, 0, @intCast(count));
    for (0..count) |i| written = writeI64(&payload, written, neighbors[i]);
    for (0..written) |i| output[i] = payload[i];
    return @intCast(written);
}
