// Clean-room bounded GBBS approximate set-cover profile; see package MIT notice.
const max_input: usize = 10;

fn storeI64LE(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| out[offset + i] = @truncate(bits >> @intCast(8 * i));
}

export fn gbbs_approximate_set_cover(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const ns64 = input[0];
    if (ns64 < 1 or ns64 > 8) return -1;
    const ns: usize = @intCast(ns64);
    const ne = ns;
    if (length != 1 + ns) return -1;
    const valid: u16 = (@as(u16, 1) << @intCast(ne)) - 1;
    var sets: [8]u16 = [_]u16{0} ** 8;
    for (0..ns) |s| {
        const value = input[1 + s];
        if (value < 0 or (@as(u64, @bitCast(value)) & ~@as(u64, valid)) != 0) return -1;
        sets[s] = @intCast(value);
        if ((sets[s] & (@as(u16, 1) << @intCast(s))) != 0) return -1;
    }
    for (0..ns) |u| for (0..ns) |v| {
        if (((sets[u] >> @intCast(v)) & 1) != ((sets[v] >> @intCast(u)) & 1)) return -1;
    };
    if (output_opt == null or capacity < 16) return -2;
    const output = output_opt.?;
    var uncovered = valid;
    var selected: u16 = 0;
    var bucket: [8]usize = [_]usize{0} ** 8;
    for (0..ns) |s| bucket[s] = @popCount(sets[s]);
    var round: usize = 0;
    while (uncovered != 0) : (round += 1) {
        var degree: [8]usize = [_]usize{0} ** 8;
        var top: usize = 0;
        for (0..ns) |s| top = @max(top, bucket[s]);
        if (top == 0) break;
        var eligible: [8]bool = [_]bool{false} ** 8;
        var eligible_count: usize = 0;
        for (0..ns) |s| if (bucket[s] == top) {
            degree[s] = @popCount(sets[s] & uncovered);
            bucket[s] = degree[s];
            eligible[s] = degree[s] >= top;
            if (eligible[s]) eligible_count += 1;
        };
        var priority: [8]usize = [_]usize{0} ** 8;
        var priority_count: usize = 0;
        for (0..ns) |r| {
            const s = (round + r) % ns;
            if (eligible[s]) { priority[priority_count] = s; priority_count += 1; }
        }
        var wins: [8]usize = [_]usize{0} ** 8;
        for (0..ne) |e| {
            const bit: u16 = @as(u16, 1) << @intCast(e);
            if ((uncovered & bit) == 0) continue;
            for (0..priority_count) |r| {
                const s = priority[r];
                if ((sets[s] & bit) != 0) { wins[s] += 1; break; }
            }
        }
        var round_cover: u16 = 0;
        for (0..ns) |s| if (eligible[s] and wins[s] >= top) { round_cover |= @as(u16, 1) << @intCast(s); };
        if (round_cover == 0 and eligible_count != 0) return -1;
        selected |= round_cover;
        var covered: u16 = 0;
        for (0..ns) |s| if ((round_cover & (@as(u16, 1) << @intCast(s))) != 0) { covered |= sets[s]; };
        uncovered &= ~covered;
        for (0..ns) |s| if ((round_cover & (@as(u16, 1) << @intCast(s))) != 0) { bucket[s] = 0; };
    }
    storeI64LE(output, 0, selected);
    storeI64LE(output, 8, uncovered);
    return 16;
}
