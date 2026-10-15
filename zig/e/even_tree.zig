const std = @import("std");
const INVALID_RESULT: i64 = std.math.minInt(i64);
const MAX_N: usize = 100;

export fn even_tree(values: [*]const i64, length: usize) i64 {
    if (length < 2) return INVALID_RESULT;
    const n_value = values[0];
    const edge_value = values[1];
    if (n_value < 2 or n_value > MAX_N or @rem(n_value, 2) != 0 or edge_value != n_value - 1) return INVALID_RESULT;
    const n: usize = @intCast(n_value);
    const edge_count: usize = @intCast(edge_value);
    if (length != 2 + 2 * edge_count) return INVALID_RESULT;
    var adjacency = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** MAX_N;
    for (0..edge_count) |i| {
        const u_value = values[2 + 2 * i];
        const v_value = values[3 + 2 * i];
        if (u_value < 1 or u_value > n_value or v_value < 1 or v_value > n_value or u_value == v_value) return INVALID_RESULT;
        const u: usize = @intCast(u_value - 1);
        const v: usize = @intCast(v_value - 1);
        if (adjacency[u][v]) return INVALID_RESULT;
        adjacency[u][v] = true;
        adjacency[v][u] = true;
    }
    var parents = [_]i32{-2} ** MAX_N;
    var stack = [_]usize{0} ** MAX_N;
    var order = [_]usize{0} ** MAX_N;
    var subtree = [_]i64{1} ** MAX_N;
    parents[0] = -1;
    var top: usize = 1;
    var order_count: usize = 0;
    while (top > 0) {
        top -= 1;
        const u = stack[top];
        order[order_count] = u;
        order_count += 1;
        for (0..n) |v| {
            if (adjacency[u][v] and parents[v] == -2) {
                parents[v] = @intCast(u);
                stack[top] = v;
                top += 1;
            }
        }
    }
    if (order_count != n) return INVALID_RESULT;
    var cuts: i64 = 0;
    var index = order_count;
    while (index > 0) {
        index -= 1;
        const u = order[index];
        if (parents[u] >= 0) subtree[@intCast(parents[u])] += subtree[u];
        if (@rem(subtree[u], 2) == 0) cuts += 1;
    }
    return cuts - 1;
}
