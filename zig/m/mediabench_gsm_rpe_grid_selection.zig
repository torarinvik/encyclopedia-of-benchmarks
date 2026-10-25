const INPUT_COUNT: usize = 40;
const MAX_INPUT_LENGTH: usize = 41;
const OUTPUT_BYTES: usize = 112;

fn asr2(value: i64) i64 {
    return if (value >= 0) value / 4 else -((-value + 3) / 4);
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn mediabench_gsm_rpe_grid_selection(
    input: ?[*]const i64, input_length: usize, output: ?[*]u8, output_capacity: usize,
) i64 {
    if (input == null or input_length == 0 or input_length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..input_length];
    for (values) |value| {
        if (value < -32768 or value > 32767) return -1;
    }
    if (input_length != INPUT_COUNT) return -1;
    var best_score: i64 = -1;
    var best_grid: i64 = 0;
    for (0..4) |grid_usize| {
        const grid: i64 = @intCast(grid_usize);
        var sum: i64 = 0;
        for (0..13) |i_usize| {
            const i: i64 = @intCast(i_usize);
            const scaled = asr2(values[@intCast(grid + 3 * i)]);
            sum += scaled * scaled;
        }
        const score = 2 * sum;
        if (score > best_score) { best_score = score; best_grid = grid; }
    }
    var staged: [14]i64 = undefined;
    staged[0] = best_grid;
    for (0..13) |i_usize| {
        const i: i64 = @intCast(i_usize);
        staged[1 + i_usize] = values[@intCast(best_grid + 3 * i)];
    }
    const out = output orelse return -2;
    if (output_capacity < OUTPUT_BYTES) return -2;
    for (0..14) |i| storeI64Le(out, 8 * i, staged[i]);
    return OUTPUT_BYTES;
}
