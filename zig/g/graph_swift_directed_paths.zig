const N: usize = 32;
const M: usize = 256;
const Q: usize = 64;

fn putI64(out: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[word * 8 + b] = @truncate(bits >> @intCast(8 * b));
}

pub export fn graph_swift_directed_paths(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3) return -1;
    const n64 = input[0]; const m64 = input[1];
    if (n64 < 1 or n64 > @as(i64, @intCast(N)) or m64 < 0 or m64 > @as(i64, @intCast(M))) return -1;
    const m: usize = @intCast(m64);
    const qp = 2 + 2 * m;
    if (length < qp + 1) return -1;
    const q64 = input[qp];
    if (q64 < 1 or q64 > @as(i64, @intCast(Q))) return -1;
    const q: usize = @intCast(q64);
    if (length != qp + 1 + 3 * q) return -1;
    var adj = [_][M]usize{[_]usize{0} ** M} ** N;
    var degree = [_]usize{0} ** N;
    for (0..m) |i| {
        const u64 = input[2 + 2 * i]; const v64 = input[3 + 2 * i];
        if (u64 < 0 or u64 >= n64 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64); adj[u][degree[u]] = @intCast(v64); degree[u] += 1;
    }
    var modes = [_]usize{0} ** Q; var starts = [_]usize{0} ** Q; var dests = [_]usize{0} ** Q;
    for (0..q) |i| {
        const p = qp + 1 + 3 * i; const mode = input[p]; const start = input[p + 1]; const dest = input[p + 2];
        if (mode < 0 or mode > 1 or start < 0 or start >= n64 or dest < 0 or dest >= n64) return -1;
        modes[i] = @intCast(mode); starts[i] = @intCast(start); dests[i] = @intCast(dest);
    }
    var lens = [_]i64{0} ** Q; var paths = [_][N]i64{[_]i64{0} ** N} ** Q;
    var words: usize = 0;
    for (0..q) |qi| {
        const start = starts[qi]; const dest = dests[qi]; lens[qi] = -1;
        if (modes[qi] == 0) {
            var stack = [_]usize{0} ** (N + 1); var next_edge = [_]usize{0} ** (N + 1); var visited = [_]bool{false} ** N; var depth: usize = 0; stack[0] = start; visited[start] = true;
            while (true) {
                const current = stack[depth];
                if (current == dest) { lens[qi] = @intCast(depth); for (0..depth) |j| paths[qi][j] = @intCast(stack[j + 1]); break; }
                if (next_edge[depth] < degree[current]) { const next = adj[current][next_edge[depth]]; next_edge[depth] += 1; if (!visited[next]) { visited[next] = true; depth += 1; stack[depth] = next; next_edge[depth] = 0; } }
                else if (depth == 0) break
                else depth -= 1;
            }
        } else {
            var parent = [_]usize{N} ** N; var queue = [_]usize{0} ** N; var head: usize = 0; var tail: usize = 0;
            parent[start] = start; queue[tail] = start; tail += 1;
            while (head < tail) { const current = queue[head]; head += 1; if (current == dest) break; for (0..degree[current]) |j| { const next = adj[current][j]; if (parent[next] == N) { parent[next] = current; queue[tail] = next; tail += 1; } } }
            if (parent[dest] != N) { var reverse = [_]usize{0} ** N; var count: usize = 0; var current = dest; while (current != start) { reverse[count] = current; count += 1; current = parent[current]; } lens[qi] = @intCast(count); for (0..count) |j| paths[qi][j] = @intCast(reverse[count - 1 - j]); }
        }
        words += 1; if (lens[qi] > 0) words += @intCast(lens[qi]);
    }
    const required = words * 8;
    if (output == null or capacity < required) return -2;
    var word: usize = 0;
    for (0..q) |qi| { putI64(output, word, lens[qi]); word += 1; var j: usize = 0; while (j < @as(usize, @intCast(@max(lens[qi], 0)))) : (j += 1) { putI64(output, word, paths[qi][j]); word += 1; } }
    return @intCast(required);
}
