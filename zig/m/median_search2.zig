const MAX_NODES: usize = 128;
const MAX_INPUT_LENGTH: usize = MAX_NODES + 1;

fn putI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn median_search2(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_NODES) return -1;
    const count: usize = @intCast(input[0]);
    if (length != count + 1) return -1;
    for (0..count) |i| {
        if (input[i + 1] < -2147483648 or input[i + 1] > 2147483647) return -1;
    }

    var next: [MAX_NODES]i32 = [_]i32{-1} ** MAX_NODES;
    for (0..count) |i| next[i] = if (i + 1 < count) @intCast(i + 1) else -1;
    var found: i32 = 0;
    var median_index: i32 = -1;
    if (count > 0) {
        var slow: i32 = 0;
        var fast: i32 = 0;
        while (next[@intCast(fast)] >= 0 and next[@intCast(next[@intCast(fast)])] >= 0) {
            slow = next[@intCast(slow)];
            fast = next[@intCast(next[@intCast(fast)])];
        }
        median_index = if (next[@intCast(fast)] >= 0) next[@intCast(slow)] else slow;
        found = 1;
    }
    if (output_opt == null or capacity < 8) return -2;
    const output = output_opt.?;
    var buffer: [8]u8 = undefined;
    putI32Le(&buffer, 0, found);
    putI32Le(&buffer, 4, median_index);
    for (0..8) |i| output[i] = buffer[i];
    return 8;
}
