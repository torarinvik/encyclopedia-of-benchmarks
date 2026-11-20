const max_updates: usize = 30;
const max_valid_input_values: usize = 1 + max_updates;
const max_parseable_input_values: usize = max_valid_input_values + 1;
const draw_space: u64 = 205891132094649;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn morris_approximate_counter_base_three(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > max_parseable_input_values) return -1;
    const input = input_opt.?;
    const updates_value = input[0];
    if (updates_value < 0 or updates_value > 30) return -1;
    const updates: usize = @intCast(updates_value);
    if (length != 1 + updates) return -1;

    var state: usize = 0;
    var threshold: u64 = draw_space;
    var estimate: u64 = 0;
    for (0..updates) |event| {
        const draw_value = input[1 + event];
        if (draw_value < 0 or @as(u64, @intCast(draw_value)) >= draw_space) return -1;
        if (@as(u64, @intCast(draw_value)) < threshold) {
            state += 1;
            threshold /= 3;
            estimate = 3 * estimate + 1;
        }
    }

    if (output_opt == null or capacity < 16) return -2;
    const output = output_opt.?;
    storeI64Le(output, 0, @intCast(state));
    storeI64Le(output, 8, @intCast(estimate));
    return 16;
}
