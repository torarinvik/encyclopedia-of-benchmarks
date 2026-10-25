const MAX_LEAVES: usize = 4;

const Combination = struct { left: i64 = 0, right: i64 = 0, operation: i32 = 0 };
const SearchState = struct {
    count: usize,
    depth_limit: usize,
    goal: i64,
    best: i64,
    stopped: bool,
    work: [2 * MAX_LEAVES]i64,
    current: [MAX_LEAVES]Combination,
    saved: [MAX_LEAVES]Combination,
};

fn distanceFrom(a: i64, b: i64) i64 { return if (a >= b) a - b else b - a; }
fn apply(a: i64, b: i64, operation: i32) i64 {
    return switch (operation) { 1 => a + b, 2 => a - b, 3 => a * b, else => @divTrunc(a, b) };
}
fn search(state: *SearchState, depth: usize, used: u32) void {
    if (state.stopped) return;
    if (depth == state.depth_limit) {
        const candidate = state.work[state.count + depth - 1];
        if (distanceFrom(candidate, state.goal) < distanceFrom(state.best, state.goal)) {
            state.best = candidate;
            for (0..depth) |i| state.saved[i] = state.current[i];
            if (state.best == state.goal) state.stopped = true;
        }
        return;
    }
    var operation: i32 = 1;
    while (operation <= 4 and !state.stopped) : (operation += 1) {
        var first: usize = 0;
        while (first < state.count + depth and !state.stopped) : (first += 1) {
            const first_bit = @as(u32, 1) << @intCast(first);
            if (used & first_bit != 0) continue;
            var second: usize = 0;
            while (second < first and !state.stopped) : (second += 1) {
                const second_bit = @as(u32, 1) << @intCast(second);
                if (used & second_bit != 0) continue;
                var left = state.work[first];
                var right = state.work[second];
                if ((operation == 3 or operation == 4) and (left == 1 or right == 1)) continue;
                if (left == 0 or right == 0) continue;
                if (operation == 4 and @rem(left, right) != 0) continue;
                if ((operation == 2 or operation == 4) and left < right) {
                    const temporary = left; left = right; right = temporary;
                }
                state.current[depth] = .{ .left = left, .right = right, .operation = operation };
                state.work[state.count + depth] = apply(left, right, operation);
                search(state, depth + 1, used | first_bit | second_bit);
            }
        }
    }
}

export fn mcgill_exptree(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > 6) return -1;
    const goal = input[0];
    const raw_count = input[1];
    if (goal < 1 or goal > 1_000_000_000 or raw_count < 1 or raw_count > 4) return -1;
    const count: usize = @intCast(raw_count);
    if (length != count + 2) return -1;
    var state = SearchState{
        .count = count, .depth_limit = 0, .goal = goal, .best = 0, .stopped = false,
        .work = @splat(0), .current = @splat(.{}), .saved = @splat(.{}),
    };
    for (0..count) |i| {
        const value = input[2 + i];
        if (value < 1 or value > 100) return -1;
        state.work[i] = value;
    }
    for (0..count) |i| {
        if (distanceFrom(state.work[i], state.goal) < distanceFrom(state.best, state.goal))
            state.best = state.work[i];
    }
    if (state.best == state.goal) return state.best;
    var depth_limit: usize = 1;
    while (depth_limit < count) : (depth_limit += 1) {
        state.depth_limit = depth_limit;
        search(&state, 0, 0);
        if (state.stopped) break;
    }
    return state.best;
}
