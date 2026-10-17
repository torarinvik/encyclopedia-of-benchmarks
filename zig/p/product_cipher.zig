const MAX_TEXT_LENGTH: i64 = 256;
const MAX_COLUMNS: i64 = 64;
const MAX_INPUT_VALUES: usize = 259;
const MAX_OUTPUT_BYTES: usize = 315;

export fn product_cipher(input: [*c]const i64, length: usize,
                         output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    if (input[0] < 1 or input[0] > MAX_COLUMNS or
        input[1] < 0 or input[1] > MAX_TEXT_LENGTH) return -1;

    const columns: usize = @intCast(input[0]);
    const text_length: usize = @intCast(input[1]);
    if (length != 2 + text_length) return -1;
    for (0..text_length) |index| {
        const byte = input[2 + index];
        if (byte < 0 or byte > 127 or byte == 10 or byte == 13) return -1;
    }

    const padded_length: usize = if (text_length == 0)
        0
    else
        ((text_length + columns - 1) / columns) * columns;
    if (padded_length > MAX_OUTPUT_BYTES) return -1;
    if (padded_length == 0) return 0;
    if (output == null or output_capacity < padded_length) return -2;

    var padded: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    for (0..text_length) |index| padded[index] = @intCast(input[2 + index] + 5);
    for (text_length..padded_length) |index| padded[index] = '/';
    const rows = padded_length / columns;
    var written: usize = 0;
    for (0..columns) |column| {
        for (0..rows) |row| {
            output[written] = padded[column + row * columns];
            written += 1;
        }
    }
    return @intCast(written);
}
