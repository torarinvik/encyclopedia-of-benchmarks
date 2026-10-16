const std = @import("std");
const max_vertices: usize = 64;
const max_edges: i64 = 2016;

fn colorVertex(vertex: usize, count: usize, adjacency: []const bool,
    colors: []i64) bool {
    if (vertex == count) return true;
    for (1..count + 1) |color| {
        var safe = true;
        for (0..count) |neighbor| {
            if (adjacency[vertex * max_vertices + neighbor] and colors[neighbor] == @as(i64, @intCast(color))) {
                safe = false;
                break;
            }
        }
        if (!safe) continue;
        colors[vertex] = @intCast(color);
        if (colorVertex(vertex + 1, count, adjacency, colors)) return true;
        colors[vertex] = 0;
    }
    return false;
}

fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

pub export fn graph_coloring_backtracking(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 0 or n_value > 64 or m_value < 0 or m_value > max_edges or
        length != 2 + 2 * @as(usize, @intCast(m_value))) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    var adjacency: [max_vertices * max_vertices]bool = @splat(false);
    for (0..m) |edge| {
        const u_value = input[2 + 2 * edge];
        const v_value = input[3 + 2 * edge];
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value)
            return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        adjacency[u * max_vertices + v] = true;
        adjacency[v * max_vertices + u] = true;
    }
    var colors: [max_vertices]i64 = @splat(0);
    if (!colorVertex(0, n, &adjacency, &colors)) return -1;
    var colors_used: i64 = 0;
    for (0..n) |vertex| if (colors[vertex] > colors_used) { colors_used = colors[vertex]; };
    var packed_values: [max_vertices + 2]i64 = @splat(0);
    packed_values[0] = n_value;
    for (0..n) |vertex| packed_values[vertex + 1] = colors[vertex];
    packed_values[n + 1] = colors_used;
    const used = n + 2;
    const required = used * 8;
    if (output == null or capacity < required) return -2;
    for (0..used) |index| putI64(output, index * 8, packed_values[index]);
    return @intCast(required);
}
