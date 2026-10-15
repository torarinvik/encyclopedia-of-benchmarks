const MAX_VERTICES: usize = 256;

fn visit(vertex: usize, n: usize, adjacency: []const bool, seen: []bool) void {
    seen[vertex] = true;
    for (0..n) |next| {
        if (adjacency[vertex * MAX_VERTICES + next] and !seen[next]) visit(next, n, adjacency, seen);
    }
}

pub export fn connected_components(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 1026) return -1;
    if (input[0] < 0 or input[0] > 256 or input[1] < 0 or input[1] > 512) return -1;
    const n: usize = @intCast(input[0]); const m: usize = @intCast(input[1]);
    if (length != 2 + 2 * m) return -1;
    var adjacency: [MAX_VERTICES * MAX_VERTICES]bool = @splat(false);
    for (0..m) |i| {
        const u = input[2 + 2 * i]; const v = input[3 + 2 * i];
        if (u < 1 or u > @as(i64, @intCast(n)) or v < 1 or v > @as(i64, @intCast(n))) return -1;
        const a: usize = @intCast(u - 1); const b: usize = @intCast(v - 1);
        adjacency[a * MAX_VERTICES + b] = true; adjacency[b * MAX_VERTICES + a] = true;
    }
    var seen: [MAX_VERTICES]bool = @splat(false);
    var components: i64 = 0;
    for (0..n) |i| {
        if (!seen[i]) { visit(i, n, adjacency[0..], seen[0..]); components += 1; }
    }
    return components;
}
