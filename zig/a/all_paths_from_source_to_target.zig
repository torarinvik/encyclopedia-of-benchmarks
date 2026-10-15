const MAX_V = 8;
const MAX_E = 24;
const MAX_PATHS = 1000;
const MAX_OUTPUT = 72008;

const Search = struct {
    adjacency: [MAX_V * MAX_E]usize = @splat(0),
    degree: [MAX_V]usize = @splat(0),
    visited: [MAX_V]bool = @splat(false),
    path: [MAX_V]usize = @splat(0),
    target: usize = 0,
    count: usize = 0,
    output: [MAX_OUTPUT]u8 = @splat(0),
    at: usize = 8,
    overflow: bool = false,
};
fn putI64(out: *[MAX_OUTPUT]u8, at: usize, value: i64) void {
    const bytes = @as(u64, @bitCast(value));
    for (0..8) |b| out[at+b] = @truncate(bytes >> @intCast(8*b));
}
fn dfs(s: *Search, current: usize, depth: usize) void {
    if (s.overflow) return;
    if (current == s.target) {
        if (s.count >= MAX_PATHS) { s.overflow = true; return; }
        putI64(&s.output, s.at, @intCast(depth)); s.at += 8;
        for (0..depth) |i| { putI64(&s.output, s.at, @intCast(s.path[i])); s.at += 8; }
        s.count += 1; return;
    }
    s.visited[current] = true;
    for (0..s.degree[current]) |i| {
        if (s.overflow) break;
        const next = s.adjacency[current * MAX_E + i];
        if (!s.visited[next]) { s.path[depth] = next; dfs(s, next, depth + 1); }
    }
    s.visited[current] = false;
}

export fn all_paths_from_source_to_target(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 4 or length > 52 or values[0] < 1 or values[0] > MAX_V or values[1] < 0 or values[1] > MAX_E) return -1;
    const nv: usize = @intCast(values[0]); const ne: usize = @intCast(values[1]);
    if (values[2] < 0 or values[2] >= @as(i64, @intCast(nv)) or values[3] < 0 or values[3] >= @as(i64, @intCast(nv)) or length != 4 + 2 * ne) return -1;
    var s = Search{ .target = @intCast(values[3]) };
    for (0..ne) |e| {
        const from = values[4 + 2*e]; const to = values[5 + 2*e];
        if (from < 0 or from >= nv or to < 0 or to >= nv) return -1;
        const u: usize = @intCast(from); s.adjacency[u * MAX_E + s.degree[u]] = @intCast(to); s.degree[u] += 1;
    }
    s.path[0] = @intCast(values[2]); dfs(&s, s.path[0], 1);
    if (s.overflow) return -2;
    putI64(&s.output, 0, @intCast(s.count));
    if (output == null or capacity < s.at) return -2;
    @memcpy(output[0..s.at], s.output[0..s.at]); return @intCast(s.at);
}
