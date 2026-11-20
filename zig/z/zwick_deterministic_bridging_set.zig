const std = @import("std");
const max_n: usize = 8;
const inf_dist: u8 = 9;

const State = struct {
    n: usize,
    threshold: usize,
    edge: [64]u8 = [_]u8{0} ** 64,
    witness: [64]u8 = [_]u8{0} ** 64,
    distance: [64]u8 = [_]u8{0} ** 64,
    constraints: [64]u16 = [_]u16{0} ** 64,
    constraint_count: usize = 0,
};

const Prefix = struct { values: [8]u8 = [_]u8{0} ** 8, count: usize = 0 };

fn popcount16(mask: u16) usize {
    var value = mask;
    var count: usize = 0;
    while (value != 0) : (value >>= 1) count += value & 1;
    return count;
}

fn subpath(state: *const State, from: usize, to: usize, limit: usize) Prefix {
    var result = Prefix{};
    const encoded = state.witness[from * state.n + to];
    if (limit == 0 or encoded == 0) return result;
    const middle: usize = @as(usize, encoded) - 1;
    result = subpath(state, from, middle, limit - 1);
    result.values[result.count] = @intCast(middle);
    result.count += 1;
    const remaining = limit - result.count;
    if (remaining > 0) {
        const suffix = subpath(state, middle, to, remaining);
        for (0..suffix.count) |i| {
            result.values[result.count] = suffix.values[i];
            result.count += 1;
        }
    }
    return result;
}

fn solve(input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 131) return -1;
    if (input[0] < 2 or input[0] > max_n) return -1;
    const n: usize = @intCast(input[0]);
    if (input[1] < 2 or input[1] > input[0] or length != 2 + 2*n*n) return -1;
    var state = State{ .n = n, .threshold = @intCast(input[1]) };
    const matrix = n*n;
    for (0..matrix) |i| {
        if (input[2+i] < 0 or input[2+i] > 1 or input[2+matrix+i] < 0 or input[2+matrix+i] > @as(i64, @intCast(n))) return -1;
        state.edge[i] = @intCast(input[2+i]);
        state.witness[i] = @intCast(input[2+matrix+i]);
    }
    for (0..n) |i| {
        if (state.edge[i*n+i] != 0) return -1;
        for (0..n) |j| state.distance[i*n+j] = if (i == j) 0 else if (state.edge[i*n+j] != 0) 1 else inf_dist;
    }
    for (0..n) |k| for (0..n) |i| for (0..n) |j| {
        const candidate = @as(usize, state.distance[i*n+k]) + state.distance[k*n+j];
        if (candidate < state.distance[i*n+j]) state.distance[i*n+j] = @intCast(candidate);
    };
    for (0..n) |i| for (0..n) |j| {
        const d = state.distance[i*n+j];
        const encoded = state.witness[i*n+j];
        if (d >= inf_dist) return -1;
        if (d <= 1) {
            if (encoded != 0) return -1;
        } else {
            if (encoded == 0) return -1;
            const middle: usize = @as(usize, encoded) - 1;
            if (middle == i or middle == j) return -1;
            const left = state.distance[i*n+middle];
            const right = state.distance[middle*n+j];
            if (@as(usize, left) + right != d or left >= d or right >= d) return -1;
        }
    };
    for (0..n) |i| for (0..n) |j| {
        const prefix = subpath(&state, i, j, state.threshold);
        var mask: u16 = (@as(u16, 1) << @intCast(i)) | (@as(u16, 1) << @intCast(j));
        for (0..prefix.count) |k| mask |= @as(u16, 1) << prefix.values[k];
        if (popcount16(mask) >= state.threshold) {
            var duplicate = false;
            for (0..state.constraint_count) |c| if (state.constraints[c] == mask) { duplicate = true; };
            if (!duplicate) {
                state.constraints[state.constraint_count] = mask;
                state.constraint_count += 1;
            }
        }
    };
    var unhit = [_]bool{false} ** 64;
    for (0..state.constraint_count) |c| unhit[c] = true;
    var remaining = state.constraint_count;
    var selected: u16 = 0;
    while (remaining > 0) {
        var best_vertex: usize = 0;
        var best_score: usize = 0;
        for (0..n) |v| {
            var score: usize = 0;
            for (0..state.constraint_count) |c| if (unhit[c] and (state.constraints[c] & (@as(u16, 1) << @intCast(v))) != 0) { score += 1; };
            if (score > best_score) { best_vertex = v; best_score = score; }
        }
        if (best_score == 0) return -1;
        selected |= @as(u16, 1) << @intCast(best_vertex);
        for (0..state.constraint_count) |c| {
            if (unhit[c] and (state.constraints[c] & (@as(u16, 1) << @intCast(best_vertex))) != 0) {
                unhit[c] = false;
                remaining -= 1;
            }
        }
    }
    return selected;
}

export fn zwick_deterministic_bridging_set(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 131) return -1;
    return solve(input, length);
}
