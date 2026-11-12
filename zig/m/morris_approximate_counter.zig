const max_updates: usize = 53;
const draw_bits: usize = 53;
const max_input_values: usize = 1 + max_updates;
const draw_limit: u64 = @as(u64, 1) << draw_bits;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn morris_approximate_counter(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > max_input_values) return -1;
    const input = input_opt.?;
    const updates_value = input[0];
    if (updates_value < 1 or updates_value > 53) return -1;
    const updates: usize = @intCast(updates_value);
    if (length != 1 + updates) return -1;

    var state: usize = 0;
    for (0..updates) |event| {
        const draw_value = input[1 + event];
        if (draw_value < 0 or @as(u64, @intCast(draw_value)) >= draw_limit) return -1;
        const threshold: u64 = @as(u64, 1) << @intCast(draw_bits - state);
        if (@as(u64, @intCast(draw_value)) < threshold) state += 1;
    }

    if (output_opt == null or capacity < 16) return -2;
    const estimate: i64 = @intCast((@as(u64, 1) << @intCast(state)) - 1);
    const output = output_opt.?;
    storeI64Le(output, 0, @intCast(state));
    storeI64Le(output, 8, estimate);
    return 16;
}
