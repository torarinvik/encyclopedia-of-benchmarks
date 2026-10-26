// Deterministic Edmonds blossom maximum-cardinality matching, n <= 12.
const n_max: usize = 12;
const input_max: usize = 134;

fn lca(match: *const [n_max]i32, parent: *const [n_max]i32, base: *const [n_max]i32, a0: usize, b0: usize) usize {
    var seen = [_]bool{false} ** n_max;
    var a = a0;
    var b = b0;
    while (true) {
        a = @intCast(base[a]);
        seen[a] = true;
        if (match[a] < 0) break;
        a = @intCast(parent[@intCast(match[a])]);
    }
    while (true) {
        b = @intCast(base[b]);
        if (seen[b]) return b;
        b = @intCast(parent[@intCast(match[b])]);
    }
}

fn markPath(match: *const [n_max]i32, parent: *[n_max]i32, base: *const [n_max]i32, blossom: *[n_max]bool, v0: usize, root: usize, child0: usize) void {
    var v = v0;
    var child = child0;
    while (@as(usize, @intCast(base[v])) != root) {
        blossom[@intCast(base[v])] = true;
        blossom[@intCast(base[@intCast(match[v])])] = true;
        parent[v] = @intCast(child);
        child = @intCast(match[v]);
        v = @intCast(parent[@intCast(match[v])]);
    }
}

fn findPath(n: usize, adj: *const [n_max][n_max]bool, matching: *[n_max]i32, parent: *[n_max]i32, base: *[n_max]i32, root: usize) bool {
    var used = [_]bool{false} ** n_max;
    var queue = [_]usize{0} ** n_max;
    var head: usize = 0;
    var tail: usize = 0;
    for (0..n) |i| { parent[i] = -1; base[i] = @intCast(i); }
    queue[tail] = root;
    tail += 1;
    used[root] = true;
    while (head < tail) {
        const v = queue[head];
        head += 1;
        for (0..n) |u| {
            if (!adj[v][u] or base[v] == base[u] or matching[v] == @as(i32, @intCast(u))) continue;
            if (u == root or (matching[u] >= 0 and parent[@intCast(matching[u])] >= 0)) {
                const cur = lca(matching, parent, base, v, u);
                var blossom = [_]bool{false} ** n_max;
                markPath(matching, parent, base, &blossom, v, cur, u);
                markPath(matching, parent, base, &blossom, u, cur, v);
                for (0..n) |i| {
                    if (blossom[@intCast(base[i])]) {
                        base[i] = @intCast(cur);
                        if (!used[i]) { used[i] = true; queue[tail] = i; tail += 1; }
                    }
                }
            } else if (parent[u] < 0) {
                parent[u] = @intCast(v);
                if (matching[u] < 0) {
                    var x: i32 = @intCast(u);
                    while (x >= 0) {
                        const pv = parent[@intCast(x)];
                        const next: i32 = if (pv >= 0) matching[@intCast(pv)] else -1;
                        if (pv >= 0) { matching[@intCast(x)] = pv; matching[@intCast(pv)] = x; }
                        x = next;
                    }
                    return true;
                }
                const mate: usize = @intCast(matching[u]);
                used[mate] = true;
                queue[tail] = mate;
                tail += 1;
            }
        }
    }
    return false;
}

export fn general_graph_maximum_matching(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > input_max) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 2 or n64 > n_max or m64 < 0 or m64 > n64 * (n64 - 1) / 2 or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var adj = [_][n_max]bool{[_]bool{false} ** n_max} ** n_max;
    for (0..m) |e| {
        const u64 = input[2 + 2 * e];
        const v64 = input[3 + 2 * e];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (adj[u][v]) return -1;
        adj[u][v] = true;
        adj[v][u] = true;
    }
    var matching = [_]i32{-1} ** n_max;
    var parent = [_]i32{-1} ** n_max;
    var base = [_]i32{0} ** n_max;
    for (0..n) |i| if (matching[i] < 0) { _ = findPath(n, &adj, &matching, &parent, &base, i); };
    var cardinality: i64 = 0;
    for (0..n) |i| if (matching[i] > @as(i32, @intCast(i))) { cardinality += 1; };
    if (output_opt == null or capacity < 8) return -2;
    const output = output_opt.?;
    const bits: u64 = @bitCast(cardinality);
    for (0..8) |i| output[i] = @truncate(bits >> @intCast(8 * i));
    return 8;
}
