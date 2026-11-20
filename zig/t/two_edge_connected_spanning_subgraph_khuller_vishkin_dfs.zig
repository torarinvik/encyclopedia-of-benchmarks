const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 59;

fn put(out: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| out[at + i] = @truncate(bits >> @intCast(8 * i));
}
fn connected(n: usize, m: usize, u: *[MAX_M]usize, v: *[MAX_M]usize, skip: isize) bool {
    var seen: [MAX_N]bool = @splat(false); var q: [MAX_N]usize = @splat(0);
    var head: usize = 0; var tail: usize = 1; q[0] = 0; seen[0] = true;
    while (head < tail) {
        const x = q[head]; head += 1;
        for (0..m) |e| {
            if (@as(isize, @intCast(e)) == skip) continue;
            var y: usize = MAX_N;
            if (u[e] == x) y = v[e] else if (v[e] == x) y = u[e];
            if (y < n and !seen[y]) { seen[y] = true; q[tail] = y; tail += 1; }
        }
    }
    for (0..n) |i| if (!seen[i]) return false;
    return true;
}
fn earlier(a: usize, b: usize, disc: *[MAX_N]usize) bool { return disc[a] < disc[b]; }

export fn two_edge_connected_spanning_subgraph_khuller_vishkin_dfs(
    input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?; const n64 = input[0]; const m64 = input[1];
    if (n64 < 3 or n64 > 8 or m64 < 3 or m64 > 28 or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64); const m: usize = @intCast(m64);
    var u: [MAX_M]usize = @splat(0); var v: [MAX_M]usize = @splat(0);
    for (0..m) |e| {
        const a = input[2 + 2 * e]; const b = input[3 + 2 * e];
        if (a < 0 or a >= b or b >= n64) return -1;
        u[e] = @intCast(a); v[e] = @intCast(b);
        for (0..e) |j| if (u[j] == u[e] and v[j] == v[e]) return -1;
    }
    if (!connected(n, m, &u, &v, -1)) return -1;
    for (0..m) |e| if (!connected(n, m, &u, &v, @intCast(e))) return -1;

    var state: [MAX_N]usize = @splat(0); var disc: [MAX_N]usize = @splat(0);
    var low: [MAX_N]usize = @splat(0); var low_h: [MAX_N]usize = @splat(0); var savior: [MAX_N]usize = @splat(0);
    var selected: [MAX_M]bool = @splat(false);
    var stack_v: [MAX_N]usize = @splat(0); var stack_parent: [MAX_N]usize = @splat(0); var stack_cursor: [MAX_N]usize = @splat(0);
    var tick: usize = 1; var top: usize = 1;
    state[0] = 1; disc[0] = 0; low[0] = 0; low_h[0] = 0; savior[0] = 0;
    stack_v[0] = 0; stack_parent[0] = MAX_N; stack_cursor[0] = 0;
    while (top > 0) {
        const frame = top - 1; const x = stack_v[frame]; const parent = stack_parent[frame];
        if (stack_cursor[frame] < m) {
            const e = stack_cursor[frame]; stack_cursor[frame] += 1;
            var y: usize = MAX_N;
            if (u[e] == x) y = v[e] else if (v[e] == x) y = u[e];
            if (y == MAX_N) continue;
            if (state[y] == 0) {
                selected[e] = true; state[y] = 1; disc[y] = tick; tick += 1;
                low[y] = y; low_h[y] = y; savior[y] = y;
                stack_v[top] = y; stack_parent[top] = x; stack_cursor[top] = 0; top += 1;
            } else if (state[y] == 1 and y != parent and earlier(y, low[x], &disc)) {
                low[x] = y; savior[x] = x;
            }
            continue;
        }
        state[x] = 2;
        if (parent < n and low_h[x] == x) {
            const a = savior[x]; const b = low[x]; const lo = @min(a, b); const hi = @max(a, b);
            for (0..m) |e| if (u[e] == lo and v[e] == hi) { selected[e] = true; break; };
            low_h[x] = low[x];
        }
        top -= 1;
        if (parent < n) {
            if (earlier(low[x], low[parent], &disc)) { low[parent] = low[x]; savior[parent] = savior[x]; }
            if (earlier(low_h[x], low_h[parent], &disc)) low_h[parent] = low_h[x];
        }
    }
    var count: usize = 0; for (0..m) |e| if (selected[e]) { count += 1; };
    const bytes = 8 * (1 + 2 * count);
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?; put(output, 0, @intCast(count)); var at: usize = 8;
    for (0..n) |a| { for (a + 1..n) |b| { for (0..m) |e| {
        if (selected[e] and u[e] == a and v[e] == b) { put(output, at, @intCast(a)); put(output, at + 8, @intCast(b)); at += 16; }
    } } }
    return @intCast(bytes);
}
