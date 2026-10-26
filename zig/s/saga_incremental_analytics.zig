// Clean-room bounded SAGA-Bench incremental analytics profile; see package LICENSE.txt.
const max_n: usize = 8;
const max_e: usize = 28;
const max_input: usize = 5 + max_n + 3 * max_e;
const inf_value: i64 = 1_000_000_000;

fn pushOnce(vertex: usize, queue: *[max_n]usize, count: *usize, seen: *[max_n]bool) void {
    if (!seen[vertex]) {
        seen[vertex] = true;
        queue[count.*] = vertex;
        count.* += 1;
    }
}

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn saga_incremental_analytics(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > max_input) return -1;
    const input = input_opt.?;
    const mode64 = input[0];
    const n64 = input[1];
    const base64 = input[2];
    const added64 = input[3];
    const source64 = input[4];
    if (mode64 < 1 or mode64 > 6 or n64 < 2 or n64 > 8 or base64 < 0 or added64 < 1 or
        base64 + added64 > @as(i64, @intCast(max_e)) or length != 5 + @as(usize, @intCast(n64)) + 3 * @as(usize, @intCast(base64 + added64))) return -1;
    const mode: usize = @intCast(mode64);
    const n: usize = @intCast(n64);
    const base_edges: usize = @intCast(base64);
    const edge_count: usize = @intCast(base64 + added64);
    if (mode == 1 or mode == 2 or mode == 5) {
        if (source64 < 0 or source64 >= n64) return -1;
    } else if (source64 != -1) return -1;

    var property: [max_n]i64 = [_]i64{0} ** max_n;
    for (0..n) |v| {
        const value = input[5 + v];
        if (mode == 1 and (value < -1 or value >= n64)) return -1;
        if ((mode == 2 or mode == 5) and (value < -1 or value > inf_value)) return -1;
        if (mode == 3 and (value < -1 or value > 1_000_000)) return -1;
        if ((mode == 4 or mode == 6) and (value < -1 or value >= n64)) return -1;
        property[v] = value;
    }
    var neighbors: [max_n][max_n]usize = [_][max_n]usize{[_]usize{0} ** max_n} ** max_n;
    var weights: [max_n][max_n]i64 = [_][max_n]i64{[_]i64{0} ** max_n} ** max_n;
    var degree: [max_n]usize = [_]usize{0} ** max_n;
    var edge_seen: [max_n][max_n]bool = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    var affected: [max_n]bool = [_]bool{false} ** max_n;
    const start = 5 + n;
    for (0..edge_count) |edge| {
        const pos = start + 3 * edge;
        const u64v = input[pos];
        const v64v = input[pos + 1];
        const weight = input[pos + 2];
        if (u64v < 0 or v64v <= u64v or v64v >= n64 or weight < 1 or weight > 9) return -1;
        const u: usize = @intCast(u64v);
        const v: usize = @intCast(v64v);
        if (edge_seen[u][v]) return -1;
        edge_seen[u][v] = true;
        edge_seen[v][u] = true;
        neighbors[u][degree[u]] = v;
        weights[u][degree[u]] = weight;
        degree[u] += 1;
        neighbors[v][degree[v]] = u;
        weights[v][degree[v]] = weight;
        degree[v] += 1;
        if (edge >= base_edges) { affected[u] = true; affected[v] = true; }
    }
    if (mode == 3) for (0..n) |v| { if (degree[v] == 0) return -1; };
    const output_bytes = 8 * n;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;

    if (mode == 1 and property[@intCast(source64)] == -1) property[@intCast(source64)] = 0;
    if (mode == 2 or mode == 5) {
        for (0..n) |v| if (property[v] == -1) {
            if (v == @as(usize, @intCast(source64))) {
                property[v] = if (mode == 2) 0 else inf_value;
            } else {
                property[v] = if (mode == 2) inf_value else 0;
            }
        };
    }
    if (mode == 4 or mode == 6) for (0..n) |v| { if (property[v] == -1) property[v] = @intCast(v); };

    if (mode == 3) {
        const damping: f32 = 0.85;
        const base = (1.0 - damping) / @as(f32, @floatFromInt(n));
        var rank: [max_n]f32 = [_]f32{0} ** max_n;
        var contribution: [max_n]f32 = [_]f32{0} ** max_n;
        for (0..n) |v| {
            rank[v] = if (property[v] == -1) 1.0 / @as(f32, @floatFromInt(n)) else @as(f32, @floatFromInt(property[v])) / 1_000_000.0;
            contribution[v] = rank[v] / @as(f32, @floatFromInt(degree[v]));
        }
        var queue: [max_n]usize = [_]usize{0} ** max_n;
        var count: usize = 0;
        var seen: [max_n]bool = [_]bool{false} ** max_n;
        for (0..n) |v| if (affected[v]) {
            var incoming: f32 = 0;
            for (0..degree[v]) |j| incoming += contribution[neighbors[v][j]];
            const old = rank[v];
            rank[v] = base + damping * incoming;
            const delta0 = rank[v] - old;
            const delta = if (delta0 < 0) -delta0 else delta0;
            if (delta > 1.0e-7) for (0..degree[v]) |j| pushOnce(neighbors[v][j], &queue, &count, &seen);
        };
        var rounds: usize = 0;
        while (count != 0) {
            rounds += 1;
            if (rounds > 256) return -1;
            for (0..n) |v| contribution[v] = rank[v] / @as(f32, @floatFromInt(degree[v]));
            const current = queue;
            const current_count = count;
            count = 0;
            seen = [_]bool{false} ** max_n;
            for (0..current_count) |q| {
                const v = current[q];
                var incoming: f32 = 0;
                for (0..degree[v]) |j| incoming += contribution[neighbors[v][j]];
                const old = rank[v];
                rank[v] = base + damping * incoming;
                const delta0 = rank[v] - old;
                const delta = if (delta0 < 0) -delta0 else delta0;
                if (delta > 1.0e-7) for (0..degree[v]) |j| pushOnce(neighbors[v][j], &queue, &count, &seen);
            }
        }
        for (0..n) |v| property[v] = @intFromFloat(rank[v] * 1_000_000.0 + 0.5);
    } else {
        var active: [max_n]usize = [_]usize{0} ** max_n;
        var active_count: usize = 0;
        for (0..n) |v| if (affected[v]) { active[active_count] = v; active_count += 1; };
        var first = true;
        var rounds: usize = 0;
        while (active_count != 0) {
            rounds += 1;
            if (rounds > 256) return -1;
            var next: [max_n]usize = [_]usize{0} ** max_n;
            var next_count: usize = 0;
            var next_seen: [max_n]bool = [_]bool{false} ** max_n;
            for (0..active_count) |a| {
                const v = active[a];
                const old = property[v];
                var candidate: i64 = 0;
                if (mode == 1 or mode == 2 or mode == 4) candidate = inf_value;
                if (mode == 1) {
                    for (0..degree[v]) |j| {
                        const p = property[neighbors[v][j]];
                        if (p != -1 and p + 1 < candidate) candidate = p + 1;
                    }
                } else if (mode == 2) {
                    for (0..degree[v]) |j| {
                        const p = property[neighbors[v][j]] + weights[v][j];
                        if (p < candidate) candidate = p;
                    }
                } else if (mode == 4) {
                    candidate = old;
                    for (0..degree[v]) |j| candidate = @min(candidate, property[neighbors[v][j]]);
                } else if (mode == 5) {
                    for (0..degree[v]) |j| candidate = @max(candidate, @min(property[neighbors[v][j]], weights[v][j]));
                } else {
                    candidate = old;
                    for (0..degree[v]) |j| candidate = @max(candidate, property[neighbors[v][j]]);
                }
                var changed = false;
                if (mode == 1) changed = candidate != inf_value and (old == -1 or candidate < old)
                else if (mode == 2) changed = candidate < old and candidate != inf_value
                else if (mode == 4) changed = candidate < old or (first and old == @as(i64, @intCast(v)))
                else if (mode == 5) changed = candidate > old
                else changed = candidate > old or (first and old == @as(i64, @intCast(v)));
                if (changed) {
                    property[v] = candidate;
                    if (mode == 1) {
                        for (0..degree[v]) |j| {
                            const neighbor = neighbors[v][j];
                            const update = property[v] + 1;
                            if (property[neighbor] == -1 or update < property[neighbor]) {
                                property[neighbor] = update;
                                pushOnce(neighbor, &next, &next_count, &next_seen);
                            }
                        }
                    } else {
                        for (0..degree[v]) |j| pushOnce(neighbors[v][j], &next, &next_count, &next_seen);
                    }
                }
            }
            active = next;
            active_count = next_count;
            first = false;
        }
    }
    for (0..n) |v| storeI64LE(output, 8 * v, property[v]);
    return @intCast(output_bytes);
}
