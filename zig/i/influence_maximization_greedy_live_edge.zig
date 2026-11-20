const MAX_N: usize = 8;
const MAX_M: usize = 24;
const MAX_WORLDS: usize = 8;

fn reachableCount(n: usize, m: usize, world: usize, seeds: u16,
    edge_u: [MAX_M]usize, edge_v: [MAX_M]usize, masks: [MAX_M]u8) i64 {
    var reached = seeds;
    var queue = [_]usize{0} ** MAX_N;
    var head: usize = 0;
    var tail: usize = 0;
    for (0..n) |vertex| {
        if (seeds & (@as(u16, 1) << @intCast(vertex))) != 0 {
            queue[tail] = vertex;
            tail += 1;
        }
    }
    while (head < tail) {
        const source = queue[head];
        head += 1;
        for (0..m) |edge| {
            const target = edge_v[edge];
            const bit: u16 = @as(u16, 1) << @intCast(target);
            if (edge_u[edge] == source and (masks[edge] & (@as(u8, 1) << @intCast(world))) != 0
                and (reached & bit) == 0) {
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

export fn influence_maximization_greedy_live_edge(input: [*c]const i64,
    length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > 77) return -1;
    const n0 = input[0];
    const m0 = input[1];
    const k0 = input[2];
    const worlds0 = input[3];
    if (n0 < 1 or n0 > 8 or m0 < 0 or m0 > 24 or k0 < 0 or k0 > n0
        or worlds0 < 1 or worlds0 > 8
        or length != 4 + 3 * @as(usize, @intCast(m0))) return -1;
    const n: usize = @intCast(n0);
    const m: usize = @intCast(m0);
    const k: usize = @intCast(k0);
    const worlds: usize = @intCast(worlds0);
    const allowed: i64 = (@as(i64, 1) << @intCast(worlds)) - 1;
    var edge_u = [_]usize{0} ** MAX_M;
    var edge_v = [_]usize{0} ** MAX_M;
    var masks = [_]u8{0} ** MAX_M;
    for (0..m) |edge| {
        const u0 = input[4 + 3 * edge];
        const v0 = input[5 + 3 * edge];
        const mask0 = input[6 + 3 * edge];
        if (u0 < 0 or u0 >= n0 or v0 < 0 or v0 >= n0 or u0 == v0
            or mask0 < 0 or mask0 > allowed) return -1;
        for (0..edge) |earlier| {
            if (edge_u[earlier] == @as(usize, @intCast(u0))
                and edge_v[earlier] == @as(usize, @intCast(v0))) return -1;
        }
        edge_u[edge] = @intCast(u0);
        edge_v[edge] = @intCast(v0);
        masks[edge] = @intCast(mask0);
    }
    var selected: u16 = 0;
    var chosen = [_]i64{0} ** MAX_N;
    var scores = [_]i64{0} ** MAX_N;
    for (0..k) |round| {
        var current = [_]i64{0} ** MAX_WORLDS;
        for (0..worlds) |world| {
            current[world] = reachableCount(n, m, world, selected, edge_u, edge_v, masks);
        }
        var best_node: i64 = -1;
        var best_score: i64 = -1;
        for (0..n) |candidate| {
            const bit: u16 = @as(u16, 1) << @intCast(candidate);
            if ((selected & bit) != 0) continue;
            var score: i64 = 0;
            for (0..worlds) |world| {
                score += reachableCount(n, m, world, selected | bit, edge_u, edge_v, masks)
                    - current[world];
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
