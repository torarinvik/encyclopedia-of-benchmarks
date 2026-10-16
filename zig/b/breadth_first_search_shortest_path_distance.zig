const MAX_VERTICES: usize = 26;
const MAX_EDGES: usize = 256;

pub export fn breadth_first_search_shortest_path_distance(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > 4 + 2 * MAX_EDGES) return -1;
    const vertices_value = input[0];
    const edges_value = input[1];
    const source_value = input[2];
    const target_value = input[3];
    if (vertices_value < 1 or vertices_value > @as(i64, @intCast(MAX_VERTICES)) or
        edges_value < 0 or edges_value > @as(i64, @intCast(MAX_EDGES))) return -1;
    const vertices: usize = @intCast(vertices_value);
    const edges: usize = @intCast(edges_value);
    if (source_value < 0 or source_value >= vertices_value or target_value < 0 or target_value >= vertices_value or
        length != 4 + 2 * edges) return -1;

    var adjacent: [MAX_VERTICES][MAX_VERTICES]bool = @splat(@splat(false));
    for (0..edges) |edge| {
        const from = input[4 + 2 * edge];
        const to = input[5 + 2 * edge];
        if (from < 0 or from >= vertices_value or to < 0 or to >= vertices_value) return -1;
        adjacent[@intCast(from)][@intCast(to)] = true;
    }

    const source: usize = @intCast(source_value);
    const target: usize = @intCast(target_value);
    var distance: [MAX_VERTICES]i64 = @splat(-1);
    var queue: [MAX_VERTICES]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 1;
    distance[source] = 0;
    queue[0] = source;
    while (head < tail) {
        const current = queue[head];
        head += 1;
        for (0..vertices) |next| {
            if (adjacent[current][next] and distance[next] < 0) {
                distance[next] = distance[current] + 1;
                queue[tail] = next;
                tail += 1;
            }
        }
    }
    return distance[target];
}
