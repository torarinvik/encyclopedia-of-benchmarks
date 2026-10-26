const max_n: usize = 16;
const max_m: usize = 16;
const max_input: usize = 34;
const max_output: usize = 136;

fn put64(output: [*]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[position + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn bitCount(value: u64) usize {
    var bits = value;
    var count: usize = 0;
    while (bits != 0) { bits &= bits - 1; count += 1; }
    return count;
}

export fn weighted_greedy_set_cover(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 16 or m64 < 1 or m64 > 16 or
        length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    const full = (@as(u64, 1) << n) - 1;
    var weights: [max_m]i64 = @splat(0);
    var masks: [max_m]u64 = @splat(0);
    var union: u64 = 0;
    for (0..m) |set| {
        weights[set] = input[2 + set];
        const mask_value = input[2 + m + set];
        if (weights[set] < 0 or weights[set] > 10000 or mask_value < 0 or
            (@as(u64, @intCast(mask_value)) & ~full) != 0) return -1;
        masks[set] = @intCast(mask_value);
        union |= masks[set];
    }
    if (union != full) return -1;

    var covered: u64 = 0;
    var selected: [max_m]usize = @splat(0);
    var selected_count: usize = 0;
    while (covered != full) {
        var best: ?usize = null;
        var best_gain: usize = 0;
        for (0..m) |set| {
            const gain = bitCount(masks[set] & ~covered);
            if (gain == 0) continue;
            const replace = if (best) |previous|
                weights[set] * @as(i64, @intCast(best_gain)) <
                    weights[previous] * @as(i64, @intCast(gain))
            else true;
            if (replace) { best = set; best_gain = gain; }
        }
        if (best == null) return -1;
        const chosen = best.?;
        selected[selected_count] = chosen;
        selected_count += 1;
        covered |= masks[chosen];
    }
    const output_bytes = 8 * (selected_count + 1);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged: [max_output]u8 = @splat(0);
    put64(&staged, 0, @intCast(selected_count));
    for (0..selected_count) |index| put64(&staged, 8 * (index + 1), @intCast(selected[index]));
    for (0..output_bytes) |index| output[index] = staged[index];
    return @intCast(output_bytes);
}
