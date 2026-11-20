const MAX_STATES: usize = 3;
const FIRST_SUBSETS: usize = 1 << MAX_STATES;
const SECOND_SUBSETS: usize = 1 << FIRST_SUBSETS;

export fn brzozowski_dfa_minimization(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > 10) return -1;
    const input = input_opt.?[0..length];
    const n64 = input[0];
    const start64 = input[1];
    const accepting64 = input[2];
    if (n64 < 1 or n64 > MAX_STATES or start64 < 0 or start64 >= n64
        or accepting64 < 0 or accepting64 >= (@as(i64, 1) << @as(u6, @intCast(n64)))) return -1;
    const n: usize = @intCast(n64);
    if (length != 3 + 2 * n) return -1;
    const start: usize = @intCast(start64);
    var transitions: [MAX_STATES][2]usize = @splat(@splat(0));
    for (0..n) |state| {
        for (0..2) |symbol| {
            const target = input[3 + 2 * state + symbol];
            if (target < 0 or target >= n64) return -1;
            transitions[state][symbol] = @intCast(target);
        }
    }

    var first_masks: [FIRST_SUBSETS]u16 = @splat(0);
    var first_delta: [FIRST_SUBSETS][2]usize = @splat(@splat(0));
    var first_final: [FIRST_SUBSETS]bool = @splat(false);
    var first_id: [FIRST_SUBSETS]i8 = @splat(-1);
    var first_count: usize = 1;
    first_masks[0] = @intCast(accepting64);
    first_id[@intCast(accepting64)] = 0;
    var cursor: usize = 0;
    while (cursor < first_count) : (cursor += 1) {
        const subset = first_masks[cursor];
        first_final[cursor] = (subset & (@as(u16, 1) << @as(u4, @intCast(start)))) != 0;
        for (0..2) |symbol| {
            var predecessor: u16 = 0;
            for (0..n) |state| {
                const bit: u16 = @as(u16, 1) << @as(u4, @intCast(transitions[state][symbol]));
                if ((subset & bit) != 0) predecessor |= @as(u16, 1) << @as(u4, @intCast(state));
            }
            const mask_index: usize = @intCast(predecessor);
            if (first_id[mask_index] < 0) {
                first_id[mask_index] = @intCast(first_count);
                first_masks[first_count] = predecessor;
                first_count += 1;
            }
            first_delta[cursor][symbol] = @intCast(first_id[mask_index]);
        }
    }

    var first_accepting: u16 = 0;
    for (0..first_count) |state| {
        if (first_final[state]) first_accepting |= @as(u16, 1) << @as(u4, @intCast(state));
    }
    var second_queue: [SECOND_SUBSETS]u16 = @splat(0);
    var second_seen: [SECOND_SUBSETS]bool = @splat(false);
    var second_count: usize = 1;
    second_queue[0] = first_accepting;
    second_seen[@intCast(first_accepting)] = true;
    cursor = 0;
    while (cursor < second_count) : (cursor += 1) {
        const subset = second_queue[cursor];
        for (0..2) |symbol| {
            var predecessor: u16 = 0;
            for (0..first_count) |state| {
                const bit: u16 = @as(u16, 1) << @as(u4, @intCast(first_delta[state][symbol]));
                if ((subset & bit) != 0) predecessor |= @as(u16, 1) << @as(u4, @intCast(state));
            }
            const mask_index: usize = @intCast(predecessor);
            if (!second_seen[mask_index]) {
                second_seen[mask_index] = true;
                second_queue[second_count] = predecessor;
                second_count += 1;
            }
        }
    }
    return @intCast(second_count);
}
