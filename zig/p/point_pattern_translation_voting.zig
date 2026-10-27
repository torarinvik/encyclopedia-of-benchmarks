const MAX_PATTERN: usize = 6;
const MAX_TARGET: usize = 8;
const MAX_PAIRS: usize = 48;
const MAX_COORD: i64 = 16;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn point_pattern_translation_voting(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 31) return -1;
    const input = input_opt.?;
    const pattern_raw, const target_raw = .{ input[0], input[1] };
    if (pattern_raw < 1 or pattern_raw > @as(i64, MAX_PATTERN) or target_raw < 1 or target_raw > @as(i64, MAX_TARGET)) return -1;
    const pattern_count: usize = @intCast(pattern_raw);
    const target_count: usize = @intCast(target_raw);
    if (length != 2 + 2 * (pattern_count + target_count)) return -1;
    var px: [MAX_PATTERN]i64 = @splat(0);
    var py: [MAX_PATTERN]i64 = @splat(0);
    var tx: [MAX_TARGET]i64 = @splat(0);
    var ty: [MAX_TARGET]i64 = @splat(0);
    var cursor: usize = 2;
    for (0..pattern_count) |i| {
        px[i] = input[cursor]; py[i] = input[cursor + 1]; cursor += 2;
        if (px[i] < -MAX_COORD or px[i] > MAX_COORD or py[i] < -MAX_COORD or py[i] > MAX_COORD) return -1;
        for (0..i) |j| if (px[i] == px[j] and py[i] == py[j]) return -1;
    }
    for (0..target_count) |i| {
        tx[i] = input[cursor]; ty[i] = input[cursor + 1]; cursor += 2;
        if (tx[i] < -MAX_COORD or tx[i] > MAX_COORD or ty[i] < -MAX_COORD or ty[i] > MAX_COORD) return -1;
        for (0..i) |j| if (tx[i] == tx[j] and ty[i] == ty[j]) return -1;
    }
    if (output_opt == null) return -2;
    const output = output_opt.?;

    var dx: [MAX_PAIRS]i64 = @splat(0);
    var dy: [MAX_PAIRS]i64 = @splat(0);
    var pair_count: usize = 0;
    for (0..pattern_count) |p| {
        for (0..target_count) |t| {
            dx[pair_count] = tx[t] - px[p]; dy[pair_count] = ty[t] - py[p]; pair_count += 1;
        }
    }
    for (1..pair_count) |i| {
        const key_x = dx[i]; const key_y = dy[i];
        var j = i;
        while (j > 0 and (dx[j - 1] > key_x or (dx[j - 1] == key_x and dy[j - 1] > key_y))) {
            dx[j] = dx[j - 1]; dy[j] = dy[j - 1]; j -= 1;
        }
        dx[j] = key_x; dy[j] = key_y;
    }
    var best_count: usize = 0;
    var best_x = dx[0]; var best_y = dy[0];
    var i: usize = 0;
    while (i < pair_count) {
        var ending = i + 1;
        while (ending < pair_count and dx[ending] == dx[i] and dy[ending] == dy[i]) ending += 1;
        if (ending - i > best_count) { best_count = ending - i; best_x = dx[i]; best_y = dy[i]; }
        i = ending;
    }
    if (capacity < 24) return -2;
    var staged: [24]u8 = @splat(0);
    store_i64_le(&staged, 0, @intCast(best_count));
    store_i64_le(&staged, 8, best_x);
    store_i64_le(&staged, 16, best_y);
    for (0..24) |byte| output[byte] = staged[byte];
    return 24;
}
