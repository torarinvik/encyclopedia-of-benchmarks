const MAX_VERTICES: usize = 16;
const MAX_EDGES: usize = 64;
const MAX_INPUT: usize = 133;
const MAX_PATHS: usize = 162;
const MAX_OUTPUT: usize = 1296;

const Search = struct {
    n: usize,
    target: usize,
    predecessor: [MAX_VERTICES * MAX_VERTICES]bool,
    useful: [MAX_VERTICES]bool,
    path: [MAX_VERTICES]u8 = @splat(0),
    staged: [MAX_OUTPUT]u8 = @splat(0),
    used: usize = 0,
    count: usize = 0,
    overflow: bool = false,

    fn visit(s: *Search, u: usize, depth: usize) void {
        if (s.overflow) return;
        s.path[depth] = @intCast(u);
        if (u == s.target) {
            if (s.count >= MAX_PATHS or s.used + depth + 2 > MAX_OUTPUT) { s.overflow = true; return; }
            for (0..depth + 1) |i| { s.staged[s.used] = s.path[i]; s.used += 1; }
            s.staged[s.used] = 0xff;
            s.used += 1;
            s.count += 1;
            return;
        }
        for (0..s.n) |v| {
            if (s.useful[v] and s.predecessor[v * MAX_VERTICES + u]) s.visit(v, depth + 1);
        }
    }
};

export fn all_shortest_paths_unweighted(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 4 or length > MAX_INPUT) return -1;
    if (values[0] < 1 or values[0] > 16 or values[1] < 0 or values[1] > 64) return -1;
    const n: usize = @intCast(values[0]);
    const m: usize = @intCast(values[1]);
    if (values[2] < 0 or values[2] >= @as(i64, @intCast(n))
        or values[3] < 0 or values[3] >= @as(i64, @intCast(n)) or length != 4 + 2 * m) return -1;
    const source: usize = @intCast(values[2]);
    const target: usize = @intCast(values[3]);

    var adjacent: [MAX_VERTICES * MAX_VERTICES]bool = @splat(false);
    for (0..m) |e| {
        const raw_u = values[4 + 2 * e];
        const raw_v = values[5 + 2 * e];
        if (raw_u < 0 or raw_u >= @as(i64, @intCast(n)) or raw_v < 0 or raw_v >= @as(i64, @intCast(n)) or raw_u == raw_v) return -1;
        const u: usize = @intCast(raw_u);
        const v: usize = @intCast(raw_v);
        if (adjacent[u * MAX_VERTICES + v]) return -1;
        adjacent[u * MAX_VERTICES + v] = true;
        adjacent[v * MAX_VERTICES + u] = true;
    }

    var distance: [MAX_VERTICES]i64 = @splat(-1);
    var queue: [MAX_VERTICES]usize = @splat(0);
    var predecessor: [MAX_VERTICES * MAX_VERTICES]bool = @splat(false);
    var head: usize = 0;
    var tail: usize = 0;
    distance[source] = 0;
    queue[tail] = source;
    tail += 1;
    while (head < tail) {
        const u = queue[head];
        head += 1;
        for (0..n) |v| {
            if (!adjacent[u * MAX_VERTICES + v]) continue;
            if (distance[v] < 0) { distance[v] = distance[u] + 1; queue[tail] = v; tail += 1; }
            if (distance[v] == distance[u] + 1) predecessor[v * MAX_VERTICES + u] = true;
        }
    }

    var useful: [MAX_VERTICES]bool = @splat(false);
    if (distance[target] >= 0) {
        var stack: [MAX_VERTICES]usize = @splat(0);
        var size: usize = 0;
        useful[target] = true;
        stack[size] = target;
        size += 1;
        while (size > 0) {
            size -= 1;
            const v = stack[size];
            for (0..n) |u| {
                if (predecessor[v * MAX_VERTICES + u] and !useful[u]) {
                    useful[u] = true;
                    stack[size] = u;
                    size += 1;
                }
            }
        }
    }

    var search = Search{ .n = n, .target = target, .predecessor = predecessor, .useful = useful };
    if (distance[target] >= 0) search.visit(source, 0);
    if (search.overflow) return -2;
    if (output == null or capacity < search.used) return -2;
    for (0..search.used) |i| output[i] = search.staged[i];
    return @intCast(search.count);
}
