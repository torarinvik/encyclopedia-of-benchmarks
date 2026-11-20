const MAX_VERTICES: usize = 12;
const MAX_EDGES: usize = 66;
const MAX_LENGTH: usize = 203;
const DISTANCE_OFFSET: i64 = 100_000;
const INFINITY_DISTANCE: i64 = 1 << 60;

export fn dag_shortest_path(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > MAX_LENGTH) return -1;
    const values = input.?;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_VERTICES))
        or values[1] < 0 or values[1] > @as(i64, @intCast(MAX_EDGES))) return -1;
    const vertex_count: usize = @intCast(values[0]);
    const edge_count: usize = @intCast(values[1]);
    if (length != 4 + 3 * edge_count) return -1;
    if (values[2] < 0 or values[2] >= @as(i64, @intCast(vertex_count))
        or values[3] < 0 or values[3] >= @as(i64, @intCast(vertex_count))) return -1;
    var from: [MAX_EDGES]i64 = undefined;
    var to: [MAX_EDGES]i64 = undefined;
    var weight: [MAX_EDGES]i64 = undefined;
    var indegree: [MAX_VERTICES]i64 = @splat(0);
    for (0..edge_count) |edge| {
        const start = values[4 + 3 * edge];
        const finish = values[5 + 3 * edge];
        const cost = values[6 + 3 * edge];
        if (start < 0 or start >= @as(i64, @intCast(vertex_count))
            or finish < 0 or finish >= @as(i64, @intCast(vertex_count))
            or start == finish or cost < -1000 or cost > 1000) return -1;
        for (0..edge) |previous| {
            if (from[previous] == start and to[previous] == finish) return -1;
        }
        from[edge] = start;
        to[edge] = finish;
        weight[edge] = cost;
        indegree[@intCast(finish)] += 1;
    }
    var queue: [MAX_VERTICES]usize = undefined;
    var order: [MAX_VERTICES]usize = undefined;
    var head: usize = 0;
    var tail: usize = 0;
    for (0..vertex_count) |vertex| {
        if (indegree[vertex] == 0) {
            queue[tail] = vertex;
            tail += 1;
        }
    }
    var order_count: usize = 0;
    while (head < tail) {
        const vertex = queue[head];
        head += 1;
        order[order_count] = vertex;
        order_count += 1;
        for (0..edge_count) |edge| {
            if (from[edge] == @as(i64, @intCast(vertex))) {
                const finish: usize = @intCast(to[edge]);
                indegree[finish] -= 1;
                if (indegree[finish] == 0) {
                    queue[tail] = finish;
                    tail += 1;
                }
            }
        }
    }
    if (order_count != vertex_count) return -1;
    var distance: [MAX_VERTICES]i64 = @splat(INFINITY_DISTANCE);
    distance[@intCast(values[2])] = 0;
    for (0..vertex_count) |position| {
        const vertex = order[position];
        if (distance[vertex] == INFINITY_DISTANCE) continue;
        for (0..edge_count) |edge| {
            if (from[edge] == @as(i64, @intCast(vertex))) {
                const finish: usize = @intCast(to[edge]);
                const candidate = distance[vertex] + weight[edge];
                if (candidate < distance[finish]) distance[finish] = candidate;
            }
        }
    }
    const answer = distance[@intCast(values[3])];
    if (answer == INFINITY_DISTANCE) return 0;
    return DISTANCE_OFFSET + answer;
}
