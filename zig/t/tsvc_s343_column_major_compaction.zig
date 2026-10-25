const MAX_ROWS: usize = 8;
const MAX_COLS: usize = 8;
const MAX_CELLS: usize = MAX_ROWS * MAX_COLS;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_CELLS;
const BYTES_PER_VALUE: usize = 8;

fn store_i64_le(output: [*c]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..BYTES_PER_VALUE) |byte| {
        output[position + byte] = @truncate(bits >> @intCast(byte * 8));
    }
}

export fn tsvc_s343_column_major_compaction(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const rows_raw = values[0];
    const cols_raw = values[1];
    if (rows_raw < 1 or rows_raw > MAX_ROWS or cols_raw < 1 or cols_raw > MAX_COLS) return -1;
    const rows: usize = @intCast(rows_raw);
    const cols: usize = @intCast(cols_raw);
    const cells = rows * cols;
    if (length != 2 + 2 * cells) return -1;
    if (output == null or output_capacity < cells * BYTES_PER_VALUE) return -2;

    const data = values[2 .. 2 + cells];
    const mask = values[2 + cells ..];
    var written: usize = 0;
    for (0..cols) |col| {
        for (0..rows) |row| {
            const index = row * cols + col;
            if (mask[index] > 0) {
                store_i64_le(output, written * BYTES_PER_VALUE, data[index]);
                written += 1;
            }
        }
    }
    return @intCast(written);
}
