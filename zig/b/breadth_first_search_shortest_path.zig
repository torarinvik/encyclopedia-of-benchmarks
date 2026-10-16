const MAX_VERTICES: usize = 32;
const MAX_EDGES: usize = 256;
const MAX_INPUT_LENGTH: usize = 4 + 2 * MAX_EDGES;
const MAX_OUTPUT_VALUES: usize = 1 + MAX_VERTICES;

fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
}

pub export fn breadth_first_search_shortest_path(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const vertex_value = input[0];
    const edge_value = input[1];
    const start_value = input[2];
    const goal_value = input[3];
    if (vertex_value < 1 or vertex_value > MAX_VERTICES or edge_value < 0 or edge_value > MAX_EDGES) return -1;
    const vertices: usize = @intCast(vertex_value);
    const edges: usize = @intCast(edge_value);
    if (length != 4 + 2 * edges or start_value < 0 or start_value >= @as(i64, @intCast(vertices))
        or goal_value < 0 or goal_value >= @as(i64, @intCast(vertices))) return -1;
    const start: usize = @intCast(start_value);
    const goal: usize = @intCast(goal_value);
    var adjacency: [MAX_VERTICES][MAX_EDGES]usize = @splat(@splat(0));
    var degree: [MAX_VERTICES]usize = @splat(0);
    for (0..edges) |edge| {
        const from = input[4 + 2 * edge];
        const to = input[5 + 2 * edge];
        if (from < 0 or from >= @as(i64, @intCast(vertices)) or to < 0 or to >= @as(i64, @intCast(vertices))) return -1;
        const source: usize = @intCast(from);
        adjacency[source][degree[source]] = @intCast(to);
        degree[source] += 1;
    }
    var parent: [MAX_VERTICES]i64 = @splat(-1);
    var visited: [MAX_VERTICES]bool = @splat(false);
    var queue: [MAX_VERTICES]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 0;
    visited[start] = true;
    queue[tail] = start;
    tail += 1;
    while (head < tail and !visited[goal]) {
        const node = queue[head];
        head += 1;
        for (0..degree[node]) |index| {
            const neighbor = adjacency[node][index];
            if (visited[neighbor]) continue;
            visited[neighbor] = true;
            parent[neighbor] = @intCast(node);
            queue[tail] = neighbor;
            tail += 1;
            if (neighbor == goal) break;
        }
    }
    var encoded: [MAX_OUTPUT_VALUES]i64 = @splat(0);
    var path_count: usize = 0;
    if (visited[goal]) {
        var reverse_path: [MAX_VERTICES]usize = undefined;
        var current: i64 = @intCast(goal);
        while (current >= 0) {
            reverse_path[path_count] = @intCast(current);
            path_count += 1;
            if (@as(usize, @intCast(current)) == start) break;
            current = parent[@intCast(current)];
        }
        for (0..path_count) |index| encoded[1 + index] = @intCast(reverse_path[path_count - 1 - index]);
    }
    encoded[0] = @intCast(path_count);
    const required = (path_count + 1) * 8;
    if (output == null or capacity < required) return -2;
    for (0..path_count + 1) |index| putI64(output, index * 8, encoded[index]);
    return @intCast(required);
}
