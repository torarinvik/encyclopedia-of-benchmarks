/// Generate Floyd's triangle as flattened little-endian 16-bit values.
const MAX_ROWS: i64 = 90;

export fn floyd_triangle(rows: i64, output: [*c]u8, output_capacity: usize) i64 {
    if (rows < 0 or rows > MAX_ROWS) return -1;
    const row_count: usize = @intCast(rows);
    const count = row_count * (row_count + 1) / 2;
    const output_length = count * 2;
    if (output_capacity < output_length or (output_length != 0 and output == null)) return -2;

    var index: usize = 0;
    var number: u16 = 1;
    var row: usize = 1;
    while (row <= row_count) : (row += 1) {
        var column: usize = 0;
        while (column < row) : (column += 1) {
            output[index * 2] = @truncate(number);
            output[index * 2 + 1] = @truncate(number >> 8);
            number += 1;
            index += 1;
        }
    }
    return @intCast(output_length);
}
