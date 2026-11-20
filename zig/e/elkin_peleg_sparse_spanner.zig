const MAX_N: usize = 20;
const MAX_M: usize = 190;
const MAX_INPUT: usize = 383;
const INF: i32 = 1000;

const Cluster = struct {
    center: usize = 0,
    radius: usize = 0,
    members: [MAX_N]bool = @splat(false),
    tree: [MAX_M]bool = @splat(false),
};
const Context = struct {
    n: usize,
    m: usize,
    adjacent: [MAX_N * MAX_N]bool = @splat(false),
    edge_index: [MAX_N * MAX_N]i32 = @splat(-1),
    distance: [MAX_N * MAX_N]i32 = @splat(INF),
};
const BfsResult = struct { parent: [MAX_N]i32, distance: [MAX_N]i32 };
const SuperResult = struct { clusters: [MAX_N]Cluster, count: usize };

fn edgeId(c: *const Context, a: usize, b: usize) ?usize {
    const lo = @min(a, b);
    const hi = @max(a, b);
    const found = c.edge_index[lo * MAX_N + hi];
    if (found < 0) return null;
    return @intCast(found);
}

fn bfs(c: *const Context, source: usize, allowed: [MAX_N]bool, restrict: bool) BfsResult {
    var result = BfsResult{ .parent = @splat(-1), .distance = @splat(INF) };
    var queue: [MAX_N]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = source;
    result.distance[source] = 0;
    while (head < tail) : (head += 1) {
        const u = queue[head];
        for (0..c.n) |v| {
            if (c.adjacent[u * MAX_N + v] and (!restrict or allowed[v]) and result.distance[v] == INF) {
                result.distance[v] = result.distance[u] + 1;
                result.parent[v] = @intCast(u);
                queue[tail] = v;
                tail += 1;
            }
        }
    }
    return result;
}

fn addTree(c: *const Context, allowed: [MAX_N]bool, root: usize, chosen: *[MAX_M]bool) usize {
    const found = bfs(c, root, allowed, true);
    var radius: usize = 0;
    for (0..c.n) |v| {
        if (!allowed[v]) continue;
        radius = @max(radius, @intCast(found.distance[v]));
        if (v != root) {
            if (edgeId(c, v, @intCast(found.parent[v]))) |edge| chosen[edge] = true;
        }
    }
    return radius;
}

fn setDistance(c: *const Context, left: [MAX_N]bool, right: [MAX_N]bool) i32 {
    var best: i32 = INF;
    for (0..c.n) |u| {
        if (!left[u]) continue;
        for (0..c.n) |v| if (right[v] and c.distance[u * MAX_N + v] < best) {
            best = c.distance[u * MAX_N + v];
        };
    }
    return best;
}

fn clusterBefore(a: Cluster, b: Cluster, n: usize) bool {
    if (a.center != b.center) return a.center < b.center;
    for (0..n) |v| {
        if (a.members[v] != b.members[v]) return a.members[v];
    }
    return false;
}

fn addConnector(c: *const Context, left: [MAX_N]bool, right: [MAX_N]bool, chosen: *[MAX_M]bool) void {
    var best_distance: i32 = INF;
    var best_path: [MAX_N]usize = @splat(0);
    var best_len: usize = 0;
    for (0..c.n) |source| {
        if (!left[source]) continue;
        const found = bfs(c, source, @splat(false), false);
        for (0..c.n) |target| {
            const d = found.distance[target];
            if (!right[target] or d == INF or d > best_distance) continue;
            var reversed: [MAX_N]usize = @splat(0);
            var len: usize = 0;
            var vertex: i32 = @intCast(target);
            while (vertex >= 0 and len < MAX_N) {
                reversed[len] = @intCast(vertex);
                len += 1;
                if (@as(usize, @intCast(vertex)) == source) break;
                vertex = found.parent[@intCast(vertex)];
            }
            if (len == 0 or reversed[len - 1] != source) continue;
            var earlier = best_len == 0 or d < best_distance;
            if (!earlier and d == best_distance) {
                for (0..len) |i| {
                    const candidate = reversed[len - 1 - i];
                    if (candidate != best_path[i]) { earlier = candidate < best_path[i]; break; }
                }
            }
            if (earlier) {
                best_distance = d;
                best_len = len;
                for (0..len) |i| best_path[i] = reversed[len - 1 - i];
            }
        }
    }
    for (1..best_len) |i| {
        if (edgeId(c, best_path[i - 1], best_path[i])) |edge| chosen[edge] = true;
    }
}

fn sigma(n: usize) usize {
    var value: usize = 1;
    while (value * value * value * value < n) : (value += 1) {}
    return value;
}

fn supercluster(c: *const Context, input: [MAX_N]Cluster, count: usize, threshold: usize,
    delta: i32, chosen: *[MAX_M]bool) SuperResult {
    var active: [MAX_N]bool = @splat(false);
    for (0..count) |i| active[i] = true;
    var output = SuperResult{ .clusters = @splat(.{}), .count = 0 };
    while (true) {
        var best: ?usize = null;
        var neighborhoods: [MAX_N * MAX_N]bool = @splat(false);
        for (0..count) |i| {
            if (!active[i]) continue;
            var close: usize = 0;
            for (0..count) |j| {
                if (active[j] and setDistance(c, input[i].members, input[j].members) <= delta) {
                    neighborhoods[i * MAX_N + j] = true;
                    close += 1;
                }
            }
            if (close >= threshold and (best == null or clusterBefore(input[i], input[best.?], c.n))) best = i;
        }
        if (best == null) break;
        const center = best.?;
        var merged = Cluster{ .center = input[center].center };
        for (0..count) |j| {
            if (!neighborhoods[center * MAX_N + j]) continue;
            active[j] = false;
            for (0..c.n) |v| merged.members[v] = merged.members[v] or input[j].members[v];
            for (0..c.m) |e| {
                merged.tree[e] = merged.tree[e] or input[j].tree[e];
                chosen[e] = chosen[e] or input[j].tree[e];
            }
            if (j != center) addConnector(c, input[center].members, input[j].members, chosen);
        }
        output.clusters[output.count] = merged;
        output.count += 1;
    }
    var remaining: [MAX_N]usize = @splat(0);
    var remaining_count: usize = 0;
    for (0..count) |i| if (active[i]) { remaining[remaining_count] = i; remaining_count += 1; };
    for (1..remaining_count) |i| {
        const key = remaining[i];
        var pos = i;
        while (pos > 0 and clusterBefore(input[key], input[remaining[pos - 1]], c.n)) : (pos -= 1) {
            remaining[pos] = remaining[pos - 1];
        }
        remaining[pos] = key;
    }
    for (0..remaining_count) |i| {
        for (i + 1..remaining_count) |j| {
            if (setDistance(c, input[remaining[i]].members, input[remaining[j]].members) <= delta)
                addConnector(c, input[remaining[i]].members, input[remaining[j]].members, chosen);
        }
    }
    return output;
}

fn construct(c: *Context) [MAX_M]bool {
    for (0..c.n) |source| {
        const found = bfs(c, source, @splat(false), false);
        for (0..c.n) |v| c.distance[source * MAX_N + v] = found.distance[v];
    }
    var chosen: [MAX_M]bool = @splat(false);
    var uncovered: [MAX_N]bool = @splat(false);
    for (0..c.n) |v| uncovered[v] = true;
    var ground: [MAX_N]Cluster = @splat(.{});
    var ground_count: usize = 0;
    while (true) {
        var root: ?usize = null;
        for (0..c.n) |v| if (uncovered[v]) { root = v; break; };
        if (root == null) break;
        var members: [MAX_N]bool = @splat(false);
        members[root.?] = true;
        var size: usize = 1;
        while (true) {
            var shell: [MAX_N]bool = @splat(false);
            var shell_size: usize = 0;
            for (0..c.n) |v| {
                shell[v] = members[v];
                if (!shell[v] and uncovered[v]) {
                    for (0..c.n) |u| if (members[u] and c.adjacent[u * MAX_N + v]) { shell[v] = true; break; };
                }
                if (shell[v]) shell_size += 1;
            }
            if (shell_size == size or shell_size * shell_size * shell_size * shell_size < c.n * size * size * size * size) break;
            for (0..c.n) |v| if (shell[v] and !members[v]) { members[v] = true; size += 1; };
        }
        var shell: [MAX_N]bool = @splat(false);
        for (0..c.n) |v| {
            shell[v] = members[v];
            if (!shell[v] and uncovered[v]) {
                for (0..c.n) |u| if (members[u] and c.adjacent[u * MAX_N + v]) { shell[v] = true; break; };
            }
        }
        var cluster = Cluster{ .center = root.? };
        cluster.members = members;
        cluster.radius = addTree(c, members, root.?, &cluster.tree);
        var shell_tree: [MAX_M]bool = @splat(false);
        _ = addTree(c, shell, root.?, &shell_tree);
        for (0..c.m) |e| chosen[e] = chosen[e] or shell_tree[e];
        ground[ground_count] = cluster;
        ground_count += 1;
        for (0..c.n) |v| if (members[v]) { uncovered[v] = false; };
    }
    var level: [MAX_N]Cluster = @splat(.{});
    var level_count: usize = 0;
    for (0..ground_count) |i| if (ground[i].radius == 1) { level[level_count] = ground[i]; level_count += 1; };
    const supers = supercluster(c, level, level_count, sigma(c.n), 16, &chosen);
    var final_clusters: [MAX_N]Cluster = @splat(.{});
    var final_count: usize = 0;
    for (0..supers.count) |i| { final_clusters[final_count] = supers.clusters[i]; final_count += 1; }
    for (0..ground_count) |i| if (ground[i].radius == 2 or ground[i].radius == 3) { final_clusters[final_count] = ground[i]; final_count += 1; };
    for (1..final_count) |i| {
        const key = final_clusters[i];
        var pos = i;
        while (pos > 0 and clusterBefore(key, final_clusters[pos - 1], c.n)) : (pos -= 1) final_clusters[pos] = final_clusters[pos - 1];
        final_clusters[pos] = key;
    }
    for (0..final_count) |i| for (i + 1..final_count) |j| {
        if (setDistance(c, final_clusters[i].members, final_clusters[j].members) <= 128)
            addConnector(c, final_clusters[i].members, final_clusters[j].members, &chosen);
    };
    return chosen;
}

pub export fn elkin_peleg_sparse_spanner(a: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (a == null or length < 2 or length > MAX_INPUT) return -1;
    const n64 = a[0];
    const m64 = a[1];
    if (n64 < 1 or n64 > MAX_N or m64 < 0 or m64 > MAX_M or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    var c = Context{ .n = @intCast(n64), .m = @intCast(m64) };
    for (0..c.m) |e| {
        const u64 = a[2 + 2 * e];
        const v64 = a[3 + 2 * e];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (c.edge_index[u * MAX_N + v] >= 0) return -1;
        c.edge_index[u * MAX_N + v] = @intCast(e);
        c.edge_index[v * MAX_N + u] = @intCast(e);
        c.adjacent[u * MAX_N + v] = true;
        c.adjacent[v * MAX_N + u] = true;
    }
    if (output == null or capacity < c.m) return -2;
    const selected = construct(&c);
    for (0..c.m) |e| output[e] = if (selected[e]) 1 else 0;
    return @intCast(c.m);
}
