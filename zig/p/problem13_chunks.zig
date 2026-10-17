const MAX_INPUT_BYTES: usize = 5000;
const MAX_INPUT_VALUES: usize = MAX_INPUT_BYTES + 1;
const CHUNK_WIDTH: usize = 50;
const MAX_OUTPUT_BYTES: usize = 10;

export fn problem13_chunks(values: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (values == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    const input = values.?;
    if (input[0] < 1 or input[0] > MAX_INPUT_BYTES or
        @as(usize, @intCast(input[0])) != length - 1) return -1;

    const byte_length: usize = @intCast(input[0]);
    for (0..byte_length) |index| {
        if (input[index + 1] < 48 or input[index + 1] > 57) return -1;
    }

    const width = @min(byte_length, CHUNK_WIDTH);
    var reversed: [CHUNK_WIDTH + 2]u8 = undefined;
    var reversed_length: usize = 0;
    var carry: i64 = 0;
    var remaining = width;
    while (remaining > 0) {
        remaining -= 1;
        var column = carry;
        var start: usize = 0;
        while (start < byte_length) : (start += CHUNK_WIDTH) {
            const chunk_length = @min(CHUNK_WIDTH, byte_length - start);
            if (remaining < chunk_length) {
                column += input[1 + start + remaining] - 48;
            }
        }
        reversed[reversed_length] = @intCast(@mod(column, 10));
        reversed_length += 1;
        carry = @divTrunc(column, 10);
    }
    while (carry > 0) {
        reversed[reversed_length] = @intCast(@mod(carry, 10));
        reversed_length += 1;
        carry = @divTrunc(carry, 10);
    }

    const output_length = @min(reversed_length, MAX_OUTPUT_BYTES);
    if (output == null or capacity < output_length) return -2;
    const result = output.?;
    for (0..output_length) |index| {
        result[index] = 48 + reversed[reversed_length - 1 - index];
    }
    return @intCast(output_length);
}
