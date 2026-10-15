/// Return the shortest common supersequence length of two packed ASCII sequences.
export fn shortest_common_supersequence_length(input_values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 512) return -1;
    const left_length = input_values[0];
    const right_length = input_values[1];
    if (left_length < 0 or left_length > 255 or right_length < 0 or right_length > 255) return -1;
    if (length != 2 + @as(usize, @intCast(left_length)) + @as(usize, @intCast(right_length))) return -1;
    for (0..@as(usize, @intCast(left_length + right_length))) |index| {
        const value = input_values[2 + index];
        if (value < 0 or value > 127) return -1;
    }

    const rows: usize = @intCast(left_length + 1);
    const columns: usize = @intCast(right_length + 1);
    var table: [256 * 256]i64 = @splat(0);
    for (1..rows) |i| {
        for (1..columns) |j| {
            const cell = i * columns + j;
            if (input_values[1 + i] == input_values[1 + @as(usize, @intCast(left_length)) + j]) {
                table[cell] = table[(i - 1) * columns + j - 1] + 1;
            } else {
                table[cell] = @max(table[(i - 1) * columns + j], table[i * columns + j - 1]);
            }
        }
    }
    return left_length + right_length - table[(rows - 1) * columns + columns - 1];
}
