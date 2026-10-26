const MAX_ROWS: usize = 8;
const MAX_COLS: usize = 8;
const MAX_INPUT: usize = 66;
const OUTPUT: usize = 24;

fn intervalCost(input: [*]const i64, rows: usize, cols: usize, begin: usize, end: usize) i64 {
    var runs: i64 = 0;
    var have_previous = false;
    var previous: i64 = 0;
    for (0..rows) |row| {
        for (begin..end) |col| {
            const value = input[2 + row * cols + col];
            if (!have_previous or value != previous) runs += 1;
            previous = value;
            have_previous = true;
        }
    }
    return 2 * runs;
}

fn putI64(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn table_compression_optimal_contiguous_partition(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const rows64 = input[0];
    const cols64 = input[1];
    if (rows64 < 1 or rows64 > 8 or cols64 < 1 or cols64 > 8) return -1;
    const rows: usize = @intCast(rows64);
    const cols: usize = @intCast(cols64);
    if (length != 2 + rows * cols) return -1;
    for (0..rows * cols) |i| if (input[2 + i] < 0 or input[2 + i] > 15) return -1;

    var cost: [MAX_COLS + 1]i64 = @splat(0);
    var previous: [MAX_COLS + 1]usize = @splat(0);
    for (1..cols + 1) |end| {
        cost[end] = 0x3fffffff;
        for (0..end) |start| {
            const candidate = cost[start] + intervalCost(input, rows, cols, start, end);
            if (candidate < cost[end]) {
                cost[end] = candidate;
                previous[end] = start;
            }
        }
    }
    var groups: i64 = 0;
    var cuts: u64 = 0;
    var end = cols;
    while (end > 0) {
        const start = previous[end];
        if (start > 0) cuts |= @as(u64, 1) << @intCast(start - 1);
        groups += 1;
        end = start;
    }
    if (output_opt == null or capacity < OUTPUT) return -2;
    var staged: [OUTPUT]u8 = @splat(0);
    putI64(&staged, 0, cost[cols]);
    putI64(&staged, 8, groups);
    putI64(&staged, 16, @intCast(cuts));
    @memcpy(output_opt.?[0..OUTPUT], staged[0..OUTPUT]);
    return @intCast(OUTPUT);
}
