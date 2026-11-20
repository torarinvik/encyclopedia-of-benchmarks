/// Bounded row-compression and Kadane maximum-sum rectangle.
const MAX_PARSEABLE_INPUT_LENGTH: usize = 67;
const OUTPUT_BYTES: usize = 8;

fn writeI64Le(output: [*c]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn maximum_sum_contiguous_submatrix(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const rows_value = input[0];
    const columns_value = input[1];
    if (rows_value < 1 or rows_value > 8 or columns_value < 1 or columns_value > 8) return -1;
    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    const cells = rows * columns;
    if (length != 2 + cells) return -1;
    for (0..cells) |index| {
        if (input[index + 2] < -1000 or input[index + 2] > 1000) return -1;
    }

    var best: i64 = -64001;
    var column_sums = [_]i64{0} ** 8;
    for (0..rows) |top| {
        for (0..columns) |column| column_sums[column] = 0;
        for (top..rows) |bottom| {
            const row_offset = 2 + bottom * columns;
            for (0..columns) |column| column_sums[column] += input[row_offset + column];
            var current = column_sums[0];
            if (current > best) best = current;
            for (1..columns) |column| {
                if (current < 0) current = column_sums[column] else current += column_sums[column];
                if (current > best) best = current;
            }
        }
    }
    if (output == null or output_capacity < OUTPUT_BYTES) return -2;
    writeI64Le(output, best);
    return OUTPUT_BYTES;
}
