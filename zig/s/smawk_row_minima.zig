const MAX_ROWS: usize = 16;
const MAX_COLUMNS: usize = 16;
const MAX_INPUT_LENGTH: usize = 260;

fn smawk(input: []const i64, column_count: usize,
         row_work: []i32, row_offset: usize, row_count: usize,
         column_work: []i32, input_column_offset: usize, input_column_count: usize,
         output_column_offset: usize, minima: []i32) void {
    if (row_count == 0) return;
    if (row_count == 1) {
        const row: usize = @intCast(row_work[row_offset]);
        var best: usize = @intCast(column_work[input_column_offset]);
        for (1..input_column_count) |j| {
            const candidate: usize = @intCast(column_work[input_column_offset + j]);
            if (input[2 + row * column_count + candidate] < input[2 + row * column_count + best]) best = candidate;
        }
        minima[row] = @intCast(best);
        return;
    }

    var reduced_count: usize = 0;
    for (0..input_column_count) |j| {
        const candidate = column_work[input_column_offset + j];
        while (reduced_count > 0) {
            const comparison_row: usize = @intCast(row_work[row_offset + reduced_count - 1]);
            const previous: usize = @intCast(column_work[output_column_offset + reduced_count - 1]);
            if (input[2 + comparison_row * column_count + @as(usize, @intCast(candidate))]
                < input[2 + comparison_row * column_count + previous]) reduced_count -= 1 else break;
        }
        if (reduced_count < row_count) {
            column_work[output_column_offset + reduced_count] = candidate;
            reduced_count += 1;
        }
    }

    const odd_offset = row_offset + row_count;
    var odd_count: usize = 0;
    var i: usize = 1;
    while (i < row_count) : (i += 2) {
        row_work[odd_offset + odd_count] = row_work[row_offset + i];
        odd_count += 1;
    }
    const child_output_offset = output_column_offset + reduced_count;
    smawk(input, column_count, row_work, odd_offset, odd_count,
          column_work, output_column_offset, reduced_count, child_output_offset, minima);

    var start_cursor: usize = 0;
    var end_cursor: usize = 0;
    i = 0;
    while (i < row_count) : (i += 2) {
        var start: usize = 0;
        if (i > 0) {
            const previous_row: usize = @intCast(row_work[row_offset + i - 1]);
            const target = minima[previous_row];
            while (start_cursor < reduced_count and column_work[output_column_offset + start_cursor] != target) : (start_cursor += 1) {}
            start = if (start_cursor < reduced_count) start_cursor else reduced_count - 1;
        }
        var last = reduced_count - 1;
        if (i + 1 < row_count) {
            const next_row: usize = @intCast(row_work[row_offset + i + 1]);
            const target = minima[next_row];
            if (end_cursor < start) end_cursor = start;
            while (end_cursor < reduced_count and column_work[output_column_offset + end_cursor] != target) : (end_cursor += 1) {}
            last = if (end_cursor < reduced_count) end_cursor else reduced_count - 1;
        }
        const row: usize = @intCast(row_work[row_offset + i]);
        var best: usize = @intCast(column_work[output_column_offset + start]);
        var position = start + 1;
        while (position <= last) : (position += 1) {
            const candidate: usize = @intCast(column_work[output_column_offset + position]);
            if (input[2 + row * column_count + candidate] < input[2 + row * column_count + best]) best = candidate;
        }
        minima[row] = @intCast(best);
    }
}

fn storeI64Le(output: *[8 * MAX_ROWS]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn smawk_row_minima(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    if (values[0] < 1 or values[0] > MAX_ROWS or values[1] < 1 or values[1] > MAX_COLUMNS) return -1;
    const row_count: usize = @intCast(values[0]);
    const column_count: usize = @intCast(values[1]);
    if (length != 2 + row_count * column_count) return -1;

    var row_work: [2 * MAX_ROWS]i32 = @splat(0);
    var column_work: [3 * MAX_COLUMNS]i32 = @splat(0);
    var minima: [MAX_ROWS]i32 = @splat(0);
    for (0..row_count) |row| row_work[row] = @intCast(row);
    for (0..column_count) |column| column_work[column] = @intCast(column);
    smawk(values, column_count, row_work[0..], 0, row_count,
          column_work[0..], 0, column_count, MAX_COLUMNS, minima[0..]);

    const output_bytes = row_count * 8;
    if (output == null or capacity < output_bytes) return -2;
    var staged: [8 * MAX_ROWS]u8 = @splat(0);
    for (0..row_count) |row| storeI64Le(&staged, row * 8, @as(i64, @intCast(minima[row])));
    const destination = output.?;
    for (0..output_bytes) |i| destination[i] = staged[i];
    return @intCast(output_bytes);
}
