/// Build a height-balanced BST from sorted unique keys and serialize it.
fn emitTree(values: []const i64, output: [*]u8, start: usize, end: usize, position: usize) usize {
    if (start == end) {
        output[position] = 0;
        return position + 1;
    }
    const middle = start + (end - start - 1) / 2;
    output[position] = 1;
    const encoded: u32 = @bitCast(@as(i32, @intCast(values[middle])));
    output[position + 1] = @truncate(encoded);
    output[position + 2] = @truncate(encoded >> 8);
    output[position + 3] = @truncate(encoded >> 16);
    output[position + 4] = @truncate(encoded >> 24);
    const next_position = emitTree(values, output, start, middle, position + 5);
    return emitTree(values, output, middle + 1, end, next_position);
}

export fn sorted_array_to_bst(input: [*]const i64, length: usize,
                              output: [*]u8, output_capacity: usize) i64 {
    if (length > 64) return -1;
    if (length > 0) {
        const values = input[0..length];
        for (values, 0..) |value, index| {
            if (value < -2147483648 or value > 2147483647) return -1;
            if (index > 0 and values[index - 1] >= value) return -1;
        }
    }
    const required = 6 * length + 1;
    if (output_capacity < required) return -2;
    if (length == 0) {
        output[0] = 0;
        return 0;
    }
    const values = input[0..length];
    _ = emitTree(values, output, 0, length, 0);
    return @intCast(length);
}
