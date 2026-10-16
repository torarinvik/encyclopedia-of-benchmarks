const MAX_TEXT: usize = 256;
const MAX_INPUT: usize = 259;

export fn transposition_cipher(input: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 6 or length > MAX_INPUT) return -1;
    const values = input.?;
    const mode = values[0]; const key64 = values[1]; const n64 = values[2];
    if ((mode != 0 and mode != 1) or n64 < 3 or n64 > MAX_TEXT or key64 < 2 or key64 >= n64) return -1;
    const n: usize = @intCast(n64); const key: usize = @intCast(key64);
    if (length != 3 + n) return -1;
    for (0..n) |i| if (values[3 + i] < 0 or values[3 + i] > 127) return -1;
    if (output == null or output_capacity < n) return -2;
    const out = output.?;

    var transformed: [MAX_TEXT]u8 = undefined;
    if (mode == 0) {
        var written: usize = 0;
        for (0..key) |column| {
            var index = column;
            while (index < n) : (index += key) {
                transformed[written] = @intCast(values[3 + index]);
                written += 1;
            }
        }
    } else {
        const columns = (n + key - 1) / key;
        const shaded = columns * key - n;
        const final_column_rows = key - shaded;
        var offsets: [MAX_TEXT]usize = undefined;
        var seen: [MAX_TEXT]usize = @splat(0);
        var total: usize = 0;
        for (0..columns) |column| {
            offsets[column] = total;
            total += if (column + 1 == columns) final_column_rows else key;
        }
        var row: usize = 0;
        var column: usize = 0;
        for (0..n) |i| {
            transformed[offsets[column] + seen[column]] = @intCast(values[3 + i]);
            seen[column] += 1;
            column += 1;
            if (column == columns or (column == columns - 1 and row >= final_column_rows)) {
                column = 0;
                row += 1;
            }
        }
    }
    @memcpy(out[0..n], transformed[0..n]);
    return @intCast(n);
}
