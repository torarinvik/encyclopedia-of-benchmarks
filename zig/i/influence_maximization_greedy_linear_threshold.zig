const MAX_N: usize = 8;
const MAX_M: usize = 24;
const MAX_WORLDS: usize = 8;
const WEIGHT_SCALE: i64 = 256;
const MAX_INPUT: usize = 141;

fn reachableCount(n: usize, seeds: u16, parents: [MAX_N]i32) i64 {
    var reached = seeds;
    var queue = [_]usize{0} ** MAX_N;
    var head: usize = 0;
    var tail: usize = 0;
    for (0..n) |vertex| {
        if (seeds & (@as(u16, 1) << @intCast(vertex)) != 0) {
            queue[tail] = vertex;
            tail += 1;
        }
    }
    while (head < tail) {
        const source = queue[head];
        head += 1;
        for (0..n) |target| {
            const bit: u16 = @as(u16, 1) << @intCast(target);
            if (parents[target] == @as(i32, @intCast(source)) and (reached & bit) == 0) {
                reached |= bit;
                queue[tail] = target;
                tail += 1;
            }
        }
    }
    return @intCast(@popCount(reached));
}

fn putI64(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn influence_maximization_greedy_linear_threshold(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 4 or length > MAX_INPUT) return -1;
    const n0 = input[0];
    const m0 = input[1];
    const k0 = input[2];
    const worlds0 = input[3];
    if (n0 < 1 or n0 > 8 or m0 < 0 or m0 > 24 or k0 < 0 or k0 > n0
        or worlds0 < 1 or worlds0 > 8) return -1;
    const n: usize = @intCast(n0);
    const m: usize = @intCast(m0);
    const k: usize = @intCast(k0);
    const worlds: usize = @intCast(worlds0);
    const expected = 4 + 3 * m + worlds * n;
    if (length != expected) return -1;

    var edge_u = [_]usize{0} ** MAX_M;
    var edge_v = [_]usize{0} ** MAX_M;
    var edge_weight = [_]i64{0} ** MAX_M;
    var incoming_sum = [_]i64{0} ** MAX_N;
    for (0..m) |edge| {
        const u0 = input[4 + 3 * edge];
        const v0 = input[5 + 3 * edge];
        const weight = input[6 + 3 * edge];
        if (u0 < 0 or u0 >= n0 or v0 < 0 or v0 >= n0 or u0 == v0
            or weight < 0 or weight > WEIGHT_SCALE) return -1;
        const u: usize = @intCast(u0);
        const v: usize = @intCast(v0);
        for (0..edge) |prior| {
            if (edge_u[prior] == u and edge_v[prior] == v) return -1;
        }
        incoming_sum[v] += weight;
        if (incoming_sum[v] > WEIGHT_SCALE) return -1;
        edge_u[edge] = u;
        edge_v[edge] = v;
        edge_weight[edge] = weight;
    }

    var draws = [_][MAX_N]i64{[_]i64{0} ** MAX_N} ** MAX_WORLDS;
    const draws_start = 4 + 3 * m;
    for (0..worlds) |world| {
        for (0..n) |vertex| {
            const draw = input[draws_start + world * n + vertex];
            if (draw < 0 or draw >= WEIGHT_SCALE) return -1;
            draws[world][vertex] = draw;
        }
    }

    var parents: [MAX_WORLDS][MAX_N]i32 = undefined;
    for (0..worlds) |world| {
        for (0..n) |target| {
            parents[world][target] = -1;
            var offset: i64 = 0;
            const ticket = draws[world][target];
            for (0..m) |edge| {
                if (edge_v[edge] != target) continue;
                const next = offset + edge_weight[edge];
                if (offset <= ticket and ticket < next) {
                    parents[world][target] = @intCast(edge_u[edge]);
                    break;
                }
                offset = next;
            }
        }
    }

    var selected: u16 = 0;
    var chosen = [_]i64{0} ** MAX_N;
    var scores = [_]i64{0} ** MAX_N;
    for (0..k) |round| {
        var current = [_]i64{0} ** MAX_WORLDS;
        for (0..worlds) |world| {
            current[world] = reachableCount(n, selected, parents[world]);
        }
        var best_node: i64 = -1;
        var best_score: i64 = -1;
        for (0..n) |candidate| {
            const bit: u16 = @as(u16, 1) << @intCast(candidate);
            if ((selected & bit) != 0) continue;
            var score: i64 = 0;
            for (0..worlds) |world| {
                score += reachableCount(n, selected | bit, parents[world]) - current[world];
            }
            if (score > best_score) {
                best_node = @intCast(candidate);
                best_score = score;
            }
        }
        if (best_node < 0) return -1;
        selected |= @as(u16, 1) << @intCast(best_node);
        chosen[round] = best_node;
        scores[round] = best_score;
    }

    const bytes = (1 + 2 * k) * 8;
    if (output == null or capacity < bytes) return -2;
    putI64(output, 0, @intCast(k));
    for (0..k) |round| {
        putI64(output, 1 + 2 * round, chosen[round]);
        putI64(output, 2 + 2 * round, scores[round]);
    }
    return @intCast(bytes);
}
