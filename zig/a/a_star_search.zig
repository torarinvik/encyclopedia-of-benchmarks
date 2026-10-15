const MAX_VERTICES: usize = 256;
const MAX_EDGES: usize = 4096;
const INF: i64 = 2305843009213693951;

export fn a_star_search(input: [*]const i64, length: usize, output: [*]u8,
    output_capacity: usize) i64 {
    if (length < 5 or length > 4 + MAX_VERTICES + 2 * MAX_EDGES) return -1;
    const vertex_value = input[0];
    const edge_value = input[1];
    const source_value = input[2];
    const target_value = input[3];
    if (vertex_value < 1 or vertex_value > MAX_VERTICES or edge_value < 0 or edge_value > MAX_EDGES) return -1;
    if (source_value < 0 or source_value >= vertex_value or target_value < 0 or target_value >= vertex_value) return -1;
    const vertices: usize = @intCast(vertex_value);
    const edges: usize = @intCast(edge_value);
    const source: usize = @intCast(source_value);
    const target: usize = @intCast(target_value);
    if (length != 4 + vertices + 2 * edges) return -1;

    var heuristic = [_]i64{0} ** MAX_VERTICES;
    var distance = [_]i64{INF} ** MAX_VERTICES;
    var parent = [_]i64{-1} ** MAX_VERTICES;
    var reversed = [_]i64{0} ** MAX_VERTICES;
    var opened = [_]bool{false} ** MAX_VERTICES;
    var closed = [_]bool{false} ** MAX_VERTICES;
    for (0..vertices) |vertex| {
        heuristic[vertex] = input[4 + vertex];
        if (heuristic[vertex] < 0 or heuristic[vertex] > 1_000_000_000) return -1;
    }
    if (heuristic[target] != 0) return -1;
    const edge_offset = 4 + vertices;
    for (0..edges) |edge| {
        const origin = input[edge_offset + 2 * edge];
        const neighbor = input[edge_offset + 2 * edge + 1];
        if (origin < 0 or origin >= vertex_value or neighbor < 0 or neighbor >= vertex_value) return -1;
        if (heuristic[@intCast(origin)] > heuristic[@intCast(neighbor)] + 1) return -1;
    }

    distance[source] = 0;
    opened[source] = true;
    while (true) {
        var best = vertices;
        for (0..vertices) |vertex| {
            if (!opened[vertex]) continue;
            if (best == vertices or distance[vertex] + heuristic[vertex] < distance[best] + heuristic[best] or
                (distance[vertex] + heuristic[vertex] == distance[best] + heuristic[best] and
                 (distance[vertex] < distance[best] or
                  (distance[vertex] == distance[best] and vertex < best)))) {
                best = vertex;
            }
        }
        if (best == vertices) break;
        opened[best] = false;
        closed[best] = true;
        if (best == target) break;
        for (0..edges) |edge| {
            if (input[edge_offset + 2 * edge] != @as(i64, @intCast(best))) continue;
            const neighbor: usize = @intCast(input[edge_offset + 2 * edge + 1]);
            if (closed[neighbor]) continue;
            const candidate = distance[best] + 1;
            if (candidate < distance[neighbor]) {
                distance[neighbor] = candidate;
                parent[neighbor] = @intCast(best);
                opened[neighbor] = true;
            }
        }
    }
    if (distance[target] == INF) return 0;

    var path_length: usize = 0;
    var current: i64 = @intCast(target);
    while (current >= 0 and path_length < vertices) {
        reversed[path_length] = current;
        path_length += 1;
        if (@as(usize, @intCast(current)) == source) break;
        current = parent[@intCast(current)];
    }
    if (path_length == 0 or @as(usize, @intCast(reversed[path_length - 1])) != source or path_length - 1 > 30) return -1;
    if (output_capacity < path_length) return -2;
    for (0..path_length) |index| {
        output[index] = @intCast(reversed[path_length - 1 - index]);
    }
    return @intCast(path_length);
}
