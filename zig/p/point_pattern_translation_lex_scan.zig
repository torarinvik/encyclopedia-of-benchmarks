const MAX_PATTERN: usize = 6;
const MAX_TARGET: usize = 8;
const MAX_COORD: i64 = 16;

fn point_less(ax: i64, ay: i64, bx: i64, by: i64) bool {
    return ax < bx or (ax == bx and ay < by);
}

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn point_pattern_translation_lex_scan(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 31) return -1;
    const input = input_opt.?;
    const pattern_raw, const target_raw = .{ input[0], input[1] };
    if (pattern_raw < 1 or pattern_raw > @as(i64, MAX_PATTERN) or target_raw < 1 or target_raw > @as(i64, MAX_TARGET) or pattern_raw > target_raw) return -1;
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
        if (i > 0 and !point_less(px[i - 1], py[i - 1], px[i], py[i])) return -1;
    }
    for (0..target_count) |i| {
        tx[i] = input[cursor]; ty[i] = input[cursor + 1]; cursor += 2;
        if (tx[i] < -MAX_COORD or tx[i] > MAX_COORD or ty[i] < -MAX_COORD or ty[i] > MAX_COORD) return -1;
        if (i > 0 and !point_less(tx[i - 1], ty[i - 1], tx[i], ty[i])) return -1;
    }
    if (output_opt == null or capacity < 24) return -2;
    const output = output_opt.?;

    var found: i64 = 0;
    var best_x: i64 = 0;
    var best_y: i64 = 0;
    for (0..target_count) |anchor| {
        const dx = tx[anchor] - px[0];
        const dy = ty[anchor] - py[0];
        var target_index = anchor + 1;
        var matches = true;
        for (1..pattern_count) |pattern_index| {
            const wanted_x = px[pattern_index] + dx;
            const wanted_y = py[pattern_index] + dy;
            while (target_index < target_count and point_less(tx[target_index], ty[target_index], wanted_x, wanted_y)) : (target_index += 1) {}
            if (target_index >= target_count or tx[target_index] != wanted_x or ty[target_index] != wanted_y) {
                matches = false;
                break;
            }
            target_index += 1;
        }
        if (matches) { found = 1; best_x = dx; best_y = dy; break; }
    }
    var staged: [24]u8 = @splat(0);
    store_i64_le(&staged, 0, found);
    store_i64_le(&staged, 8, best_x);
    store_i64_le(&staged, 16, best_y);
    for (0..24) |byte| output[byte] = staged[byte];
    return 24;
}
