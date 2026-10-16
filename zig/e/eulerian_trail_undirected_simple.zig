const MAX_V: usize = 10;
const MAX_E: usize = 45;
fn dfs(u: usize, neighbors: *const [MAX_V][MAX_E]usize, degree: *const [MAX_V]usize, seen: *[MAX_V][MAX_V]bool, path: *[MAX_E + 1]i64, count: *usize) void {
    path[count.*] = @intCast(u); count.* += 1;
    for (0..degree[u]) |i| { const v = neighbors[u][i]; if (!seen[u][v]) { seen[u][v] = true; seen[v][u] = true; dfs(v, neighbors, degree, seen, path, count); } }
}
fn put(out: [*]u8, slot: usize, value: i64) void { const bits: u64 = @bitCast(value); for (0..8) |i| out[slot * 8 + i] = @truncate(bits >> @intCast(i * 8)); }
export fn eulerian_trail_undirected_simple(input: [*]const i64, length: usize, output: [*]u8, capacity: usize) i64 {
    if (length < 2) return -1; const n0 = input[0]; const m0 = input[1]; if (n0 < 2 or n0 > MAX_V or m0 < 0 or m0 > MAX_E) return -1;
    const n: usize = @intCast(n0); const m: usize = @intCast(m0); if (length != 2 + 2 * m) return -1;
    var neighbors: [MAX_V][MAX_E]usize = undefined; var degree: [MAX_V]usize = @splat(0); var adjacent: [MAX_V][MAX_V]bool = @splat(@splat(false));
    for (0..m) |i| { const a = input[2 + 2 * i]; const b = input[3 + 2 * i]; if (a < 0 or b < 0 or a >= n0 or b >= n0 or a == b) return -1; const u: usize = @intCast(a); const v: usize = @intCast(b); if (adjacent[u][v]) return -1; adjacent[u][v] = true; adjacent[v][u] = true; neighbors[u][degree[u]] = v; degree[u] += 1; neighbors[v][degree[v]] = u; degree[v] += 1; }
    var odd: usize = 0; var start: usize = 1; for (0..n) |v| { if (degree[v] % 2 == 1) { odd += 1; start = v; } } if (odd != 0 and odd != 2) return -1; const status: i64 = if (odd == 0) 1 else 2; if (status == 1) start = 1;
    if (m > 0) { if (status == 1 and degree[1] == 0) return -1; var reached: [MAX_V]bool = @splat(false); var stack: [MAX_V]usize = undefined; var top: usize = 0; stack[top] = start; top += 1; reached[start] = true; while (top > 0) { top -= 1; const u = stack[top]; for (0..degree[u]) |i| { const v = neighbors[u][i]; if (!reached[v]) { reached[v] = true; stack[top] = v; top += 1; } } } for (0..n) |v| { if (degree[v] > 0 and !reached[v]) return -1; } }
    var seen: [MAX_V][MAX_V]bool = @splat(@splat(false)); var path: [MAX_E + 1]i64 = undefined; var count: usize = 0; dfs(start, &neighbors, &degree, &seen, &path, &count); if (count != m + 1) return -1; const bytes = (2 + count) * 8; if (capacity < bytes) return -2; put(output, 0, status); put(output, 1, @intCast(count)); for (0..count) |i| put(output, 2 + i, path[i]); return @intCast(bytes);
}
