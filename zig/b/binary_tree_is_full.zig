const MAX_N: usize = 1024;
export fn binary_tree_is_full(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(input[0]);
    const root_value = input[1];
    if (root_value < 0 or root_value >= @as(i64, @intCast(n)) or length != 2 + 2 * n) return -1;
    var left: [MAX_N]i64 = undefined;
    var right: [MAX_N]i64 = undefined;
    var parents: [MAX_N]usize = undefined;
    var stack: [MAX_N]usize = undefined;
    var seen: [MAX_N]bool = undefined;
    for (0..n) |i| {
        parents[i] = 0;
        seen[i] = false;
    }
    var full = true;
    for (0..n) |i| {
        const l = input[2 + 2 * i];
        const r = input[3 + 2 * i];
        if (l < -1 or l >= @as(i64, @intCast(n)) or r < -1 or r >= @as(i64, @intCast(n)) or l == @as(i64, @intCast(i)) or r == @as(i64, @intCast(i))) return -1;
        left[i] = @intCast(l);
        right[i] = @intCast(r);
        if (l >= 0) parents[@intCast(l)] += 1;
        if (r >= 0) parents[@intCast(r)] += 1;
        if ((l < 0) != (r < 0)) full = false;
    }
    const root: usize = @intCast(root_value);
    if (parents[root] != 0) return -1;
    for (0..n) |i| {
        if (i != root and parents[i] != 1) return -1;
    }
    var top: usize = 1;
    var visited: usize = 0;
    stack[0] = root;
    while (top > 0) {
        top -= 1;
        const node = stack[top];
        if (seen[node]) return -1;
        seen[node] = true;
        visited += 1;
        if (left[node] >= 0) {
            stack[top] = @intCast(left[node]);
            top += 1;
        }
        if (right[node] >= 0) {
            stack[top] = @intCast(right[node]);
            top += 1;
        }
    }
    if (visited != n) return -1;
    return if (full) 1 else 0;
}
