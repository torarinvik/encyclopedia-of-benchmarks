const MAX: usize = 8;
const Path = struct { len: usize, nodes: [MAX]i64, cost: i64 };

fn less(a: Path, b: Path) bool {
    if (a.cost != b.cost) return a.cost < b.cost;
    const limit = @min(a.len, b.len);
    for (0..limit) |i| {
        if (a.nodes[i] != b.nodes[i]) return a.nodes[i] < b.nodes[i];
    }
    return a.len < b.len;
}
fn same(a: Path, b: Path) bool {
    if (a.len != b.len) return false;
    for (0..a.len) |i| if (a.nodes[i] != b.nodes[i]) return false;
    return true;
}
fn has(path: Path, vertex: usize) bool {
    for (0..path.len) |i| if (@as(usize, @intCast(path.nodes[i])) == vertex) return true;
    return false;
}
fn begins(path: Path, root: Path, length: usize) bool {
    if (path.len < length or root.len < length) return false;
    for (0..length) |i| if (path.nodes[i] != root.nodes[i]) return false;
    return true;
}
fn shortest(n: usize, src: usize, dst: usize, graph: [64]i64, blocked_nodes: [MAX]bool, blocked_edges: [64]bool) ?Path {
    var current: [MAX]i64 = @splat(0);
    var next: [MAX]usize = @splat(0);
    var path_cost: [MAX]i64 = @splat(0);
    var depth: usize = 1;
    current[0] = @intCast(src);
    var found = false;
    var best = Path{ .len = 0, .nodes = @splat(0), .cost = 0 };
    while (depth > 0) {
        const u: usize = @intCast(current[depth - 1]);
        if (u == dst) {
            const candidate = Path{ .len = depth, .nodes = current, .cost = path_cost[depth - 1] };
            if (!found or less(candidate, best)) { best = candidate; found = true; }
            depth -= 1;
            continue;
        }
        if (next[depth - 1] >= n) { next[depth - 1] = 0; depth -= 1; continue; }
        const v = next[depth - 1];
        next[depth - 1] += 1;
        const weight = graph[u * n + v];
        if (weight < 0 or blocked_nodes[v] or blocked_edges[u * MAX + v]) continue;
        var repeated = false;
        for (0..depth) |i| if (@as(usize, @intCast(current[i])) == v) { repeated = true; };
        if (repeated) continue;
        current[depth] = @intCast(v);
        path_cost[depth] = path_cost[depth - 1] + weight;
        next[depth] = 0;
        depth += 1;
    }
    return if (found) best else null;
}
fn put(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[offset + b] = @truncate(bits >> @intCast(b * 8));
}

export fn yens_kshortest_paths(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4) return -1;
    const nv = input[0]; const kv = input[1]; const srcv = input[2]; const dstv = input[3];
    if (nv < 1 or nv > 8 or kv < 1 or kv > 8 or srcv < 0 or srcv >= nv or dstv < 0 or dstv >= nv) return -1;
    const n: usize = @intCast(nv); const k: usize = @intCast(kv); const src: usize = @intCast(srcv); const dst: usize = @intCast(dstv);
    if (length != 4 + n * n) return -1;
    var graph: [64]i64 = @splat(-1);
    for (0..n * n) |i| { const weight = input[4 + i]; if (weight < -1 or weight > 1000) return -1; graph[i] = weight; }
    var accepted: [MAX]Path = undefined; var accepted_count: usize = 0;
    var candidates: [64]Path = undefined; var candidate_count: usize = 0;
    const no_nodes: [MAX]bool = @splat(false); const no_edges: [64]bool = @splat(false);
    if (shortest(n, src, dst, graph, no_nodes, no_edges)) |first| { accepted[0] = first; accepted_count = 1; }
    while (accepted_count < k and accepted_count > 0) {
        const last = accepted[accepted_count - 1];
        for (0..last.len - 1) |spur_index| {
            var root = Path{ .len = spur_index + 1, .nodes = @splat(0), .cost = 0 };
            for (0..root.len) |j| root.nodes[j] = last.nodes[j];
            for (0..spur_index) |j| root.cost += graph[@as(usize, @intCast(root.nodes[j])) * n + @as(usize, @intCast(root.nodes[j + 1]))];
            var blocked_nodes: [MAX]bool = @splat(false); var blocked_edges: [64]bool = @splat(false);
            for (0..spur_index) |j| blocked_nodes[@intCast(root.nodes[j])] = true;
            for (0..accepted_count) |p| {
                if (begins(accepted[p], root, root.len) and accepted[p].len > root.len) {
                    const u: usize = @intCast(accepted[p].nodes[spur_index]); const v: usize = @intCast(accepted[p].nodes[spur_index + 1]);
                    blocked_edges[u * MAX + v] = true;
                }
            }
            if (shortest(n, @intCast(root.nodes[spur_index]), dst, graph, blocked_nodes, blocked_edges)) |spur| {
                var total = root;
                for (1..spur.len) |j| { total.nodes[total.len] = spur.nodes[j]; total.len += 1; }
                total.cost += spur.cost;
                var duplicate = false;
                for (0..accepted_count) |p| if (same(total, accepted[p])) { duplicate = true; };
                for (0..candidate_count) |p| if (same(total, candidates[p])) { duplicate = true; };
                if (!duplicate and candidate_count < candidates.len) { candidates[candidate_count] = total; candidate_count += 1; }
            }
        }
        if (candidate_count == 0) break;
        var best: usize = 0;
        for (1..candidate_count) |i| if (less(candidates[i], candidates[best])) { best = i; };
        accepted[accepted_count] = candidates[best]; accepted_count += 1;
        candidate_count -= 1; candidates[best] = candidates[candidate_count];
    }
    var bytes: usize = 8;
    for (0..accepted_count) |i| bytes += (accepted[i].len + 2) * 8;
    if (output == null or capacity < bytes) return -2;
    put(output, 0, @intCast(accepted_count)); var at: usize = 8;
    for (0..accepted_count) |i| { put(output, at, @intCast(accepted[i].len)); at += 8; for (0..accepted[i].len) |j| { put(output, at, accepted[i].nodes[j]); at += 8; } put(output, at, accepted[i].cost); at += 8; }
    return @intCast(bytes);
}
