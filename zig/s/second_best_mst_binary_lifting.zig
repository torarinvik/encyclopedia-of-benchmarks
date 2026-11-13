const Pair = [2]i64;

fn merge(a: Pair, b: Pair) Pair {
    var result = Pair{ -1, -1 };
    for ([_]i64{ a[0], a[1], b[0], b[1] }) |value| {
        if (value > result[0]) {
            result[1] = result[0];
            result[0] = value;
        } else if (value < result[0] and value > result[1]) {
            result[1] = value;
        }
    }
    return result;
}

fn root(parent: *[8]usize, initial: usize) usize {
    var vertex = initial;
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

export fn second_best_mst_binary_lifting(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 63) return -1;
    const input = input_opt.?;
    const nv = input[0];
    const mv = input[1];
    if (nv < 1 or nv > 8 or mv < nv - 1 or mv > 20 or length != @as(usize, @intCast(2 + 3 * mv))) return -1;
    const n: usize = @intCast(nv);
    const m: usize = @intCast(mv);
    var u = [_]usize{0} ** 20;
    var v = [_]usize{0} ** 20;
    var order = [_]usize{0} ** 20;
    var weight = [_]i64{0} ** 20;
    var seen = [_]bool{false} ** 64;
    for (0..m) |i| {
        const a = input[2 + 3 * i];
        const b = input[3 + 3 * i];
        const w = input[4 + 3 * i];
        if (a < 0 or a >= b or b >= nv or w < 0 or w > 1000000) return -1;
        const pos: usize = @intCast(a * 8 + b);
        if (seen[pos]) return -1;
        seen[pos] = true;
        u[i] = @intCast(a); v[i] = @intCast(b); weight[i] = w; order[i] = i;
    }
    var i: usize = 1;
    while (i < m) : (i += 1) {
        const edge = order[i];
        var j = i;
        while (j > 0 and weight[order[j - 1]] > weight[edge]) : (j -= 1) order[j] = order[j - 1];
        order[j] = edge;
    }
    var parent = [_]usize{0} ** 8;
    var degree = [_]usize{0} ** 8;
    var adjacent = [_]usize{0} ** 64;
    var edge_at = [_]usize{0} ** 64;
    var selected = [_]bool{false} ** 20;
    for (0..n) |vertex| parent[vertex] = vertex;
    var count: usize = 0;
    var total: i64 = 0;
    for (0..m) |index| {
        const edge = order[index];
        const a = root(&parent, u[edge]);
        const b = root(&parent, v[edge]);
        if (a == b) continue;
        parent[a] = b; selected[edge] = true; count += 1; total += weight[edge];
        const pu = u[edge] * 8 + degree[u[edge]];
        const pv = v[edge] * 8 + degree[v[edge]];
        adjacent[pu] = v[edge]; adjacent[pv] = u[edge];
        edge_at[pu] = edge; edge_at[pv] = edge;
        degree[u[edge]] += 1; degree[v[edge]] += 1;
    }
    if (count != n - 1) return -1;
    var up = [_]usize{0} ** 32;
    var best = [_]Pair{.{ -1, -1 }} ** 32;
    var depth = [_]i32{-1} ** 8;
    var queue = [_]usize{0} ** 8;
    depth[0] = 0;
    var head: usize = 0;
    var tail: usize = 1;
    while (head < tail) {
        const vertex = queue[head];
        head += 1;
        for (0..degree[vertex]) |index| {
            const pos = vertex * 8 + index;
            const next = adjacent[pos];
            if (depth[next] >= 0) continue;
            depth[next] = depth[vertex] + 1;
            up[next] = vertex;
            best[next] = .{ weight[edge_at[pos]], -1 };
            queue[tail] = next;
            tail += 1;
        }
    }
    for (1..4) |level| {
        for (0..n) |vertex| {
            const prev = (level - 1) * 8 + vertex;
            const other = (level - 1) * 8 + up[prev];
            const dest = level * 8 + vertex;
            up[dest] = up[other];
            best[dest] = merge(best[prev], best[other]);
        }
    }
    var increase: i64 = -1;
    for (0..m) |edge| {
        if (selected[edge]) continue;
        var a = u[edge];
        var b = v[edge];
        if (depth[a] < depth[b]) { const tmp = a; a = b; b = tmp; }
        var path = Pair{ -1, -1 };
        const difference: u32 = @intCast(depth[a] - depth[b]);
        for (0..4) |level| {
            if (difference & (@as(u32, 1) << @as(u5, @intCast(level))) != 0) {
                const pos = level * 8 + a;
                path = merge(path, best[pos]); a = up[pos];
            }
        }
        if (a != b) {
            var level: usize = 4;
            while (level > 0) {
                level -= 1;
                const pa = level * 8 + a;
                const pb = level * 8 + b;
                if (up[pa] != up[pb]) {
                    path = merge(merge(path, best[pa]), best[pb]);
                    a = up[pa]; b = up[pb];
                }
            }
            path = merge(merge(path, best[a]), best[b]);
        }
        const removed = if (weight[edge] > path[0]) path[0] else path[1];
        if (removed >= 0 and removed < weight[edge]) {
            const delta = weight[edge] - removed;
            if (increase < 0 or delta < increase) increase = delta;
        }
    }
    return if (increase < 0) 0 else total + increase + 1;
}
