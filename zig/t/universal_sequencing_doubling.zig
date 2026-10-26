const N: usize = 12;
const MAX_WEIGHT: usize = 32;
const MAX_LEVELS: usize = 6;
const MAX_INPUT: usize = 25;
const MAX_OUTPUT: usize = 104;

fn putI64(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn universal_sequencing_doubling(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 12 or length != 1 + 2 * @as(usize, @intCast(input[0]))) return -1;
    const n: usize = @intCast(input[0]);
    var processing: [N]i64 = @splat(0);
    var weights: [N]usize = @splat(0);
    var total_weight: usize = 0;
    for (0..n) |job| {
        const p = input[1 + 2 * job];
        const w = input[2 + 2 * job];
        if (p < 1 or p > 255 or w < 1 or w > 32) return -1;
        processing[job] = p;
        weights[job] = @intCast(w);
        total_weight += @intCast(w);
    }
    if (total_weight > MAX_WEIGHT or total_weight & (total_weight - 1) != 0) return -1;
    var level_sets: [MAX_LEVELS]u16 = @splat(0);
    var levels: usize = 0;
    var bound: usize = 1;
    while (bound <= total_weight) : (bound *= 2) {
        var best: [MAX_WEIGHT + 1]i64 = @splat(0);
        var masks: [MAX_WEIGHT + 1]u16 = @splat(0);
        var reachable: [MAX_WEIGHT + 1]bool = @splat(false);
        reachable[0] = true;
        for (0..n) |job| {
            var used = bound;
            while (used >= weights[job]) : (used -= 1) {
                if (!reachable[used - weights[job]]) continue;
                const candidate = best[used - weights[job]] + processing[job];
                const candidate_mask = masks[used - weights[job]] | (@as(u16, 1) << @intCast(job));
                if (!reachable[used] or candidate > best[used] or
                    (candidate == best[used] and candidate_mask < masks[used])) {
                    reachable[used] = true;
                    best[used] = candidate;
                    masks[used] = candidate_mask;
                }
            }
        }
        var maximum: i64 = -1;
        var selected: u16 = 0;
        for (0..bound + 1) |used| {
            if (reachable[used] and (best[used] > maximum or
                (best[used] == maximum and masks[used] < selected))) {
                maximum = best[used];
                selected = masks[used];
            }
        }
        level_sets[levels] = selected;
        levels += 1;
    }
    var rank: [N]i32 = @splat(-1);
    for (0..n) |job| {
        for (0..levels) |level| {
            if (level_sets[level] & (@as(u16, 1) << @intCast(job)) != 0) {
                rank[job] = @intCast(level);
                break;
            }
        }
        if (rank[job] < 0) return -1;
    }
    var words: [N + 1]i64 = @splat(0);
    words[0] = @intCast(n);
    var count: usize = 1;
    var reverse: usize = 0;
    while (reverse < levels) : (reverse += 1) {
        const level = levels - 1 - reverse;
        for (0..n) |job| if (rank[job] == level) {
            words[count] = @intCast(job);
            count += 1;
        };
    }
    const bytes = 8 * count;
    if (output_opt == null or capacity < bytes) return -2;
    var staged: [MAX_OUTPUT]u8 = @splat(0);
    for (0..count) |i| putI64(&staged, 8 * i, words[i]);
    @memcpy(output_opt.?[0..bytes], staged[0..bytes]);
    return @intCast(bytes);
}
