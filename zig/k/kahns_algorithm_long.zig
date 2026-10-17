const MAX_VERTICES: usize = 32;
const MAX_EDGES: usize = 128;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES;

export fn kahns_algorithm_long(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const vertex_count = values[0];
    const edge_count = values[1];
    if (vertex_count < 1 or vertex_count > MAX_VERTICES or edge_count < 0 or edge_count > MAX_EDGES or
        length != @as(usize, @intCast(2 + 2 * edge_count))) return -1;

    var multiplicity = [_]i64{0} ** (MAX_VERTICES * MAX_VERTICES);
    var indegree = [_]i64{0} ** MAX_VERTICES;
    var distance = [_]i64{0} ** MAX_VERTICES;
    var queue = [_]usize{0} ** MAX_VERTICES;
    for (0..@intCast(vertex_count)) |vertex| distance[vertex] = 1;
    for (0..@intCast(edge_count)) |edge| {
        const source = values[2 + 2 * edge];
        const destination = values[3 + 2 * edge];
        if (source < 0 or source >= vertex_count or destination < 0 or destination >= vertex_count) return -1;
        const source_index: usize = @intCast(source);
        const destination_index: usize = @intCast(destination);
        multiplicity[source_index * MAX_VERTICES + destination_index] += 1;
        indegree[destination_index] += 1;
    }

    var head: usize = 0;
    var tail: usize = 0;
    for (0..@intCast(vertex_count)) |vertex| {
        if (indegree[vertex] == 0) { queue[tail] = vertex; tail += 1; }
    }
    var processed: i64 = 0;
    var maximum: i64 = 1;
    while (head < tail) {
        const source = queue[head];
        head += 1;
        processed += 1;
        maximum = @max(maximum, distance[source]);
        for (0..@intCast(vertex_count)) |destination| {
            const copies = multiplicity[source * MAX_VERTICES + destination];
            if (copies == 0) continue;
            distance[destination] = @max(distance[destination], distance[source] + 1);
            for (0..@intCast(copies)) |_| {
                indegree[destination] -= 1;
                if (indegree[destination] == 0) { queue[tail] = destination; tail += 1; }
            }
        }
    }
    if (processed != vertex_count) return -1;
    for (0..@intCast(vertex_count)) |vertex| maximum = @max(maximum, distance[vertex]);
    return maximum;
}
