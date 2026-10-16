const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 256;
const MAX_INPUT_LENGTH: usize = 4 + 3 * MAX_EDGES;
const MAX_DEQUE_CAPACITY: usize = MAX_VERTICES * MAX_VERTICES + 1;
const INF: i64 = 1_000_000_000;

pub export fn breadth_first_search_zero_one_shortest_path(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -2;
    const vertex_value = input[0];
    const edge_value = input[1];
    const start_value = input[2];
    const finish_value = input[3];
    if (vertex_value < 1 or vertex_value > @as(i64, @intCast(MAX_VERTICES)) or
        edge_value < 0 or edge_value > @as(i64, @intCast(MAX_EDGES))) return -2;
    const vertices: usize = @intCast(vertex_value);
    const edges: usize = @intCast(edge_value);
    if (length != 4 + 3 * edges or start_value < 0 or start_value >= vertex_value or
        finish_value < 0 or finish_value >= vertex_value) return -2;

    var edge_to: [MAX_EDGES]usize = @splat(0);
    var edge_weight: [MAX_EDGES]i64 = @splat(0);
    var next_edge: [MAX_EDGES]i64 = @splat(-1);
    var head_edge: [MAX_VERTICES]i64 = @splat(-1);
    var tail_edge: [MAX_VERTICES]i64 = @splat(-1);
    for (0..edges) |edge| {
        const from = input[4 + 3 * edge];
        const to = input[5 + 3 * edge];
        const weight = input[6 + 3 * edge];
        if (from < 0 or from >= vertex_value or to < 0 or to >= vertex_value or
            (weight != 0 and weight != 1)) return -2;
        const source: usize = @intCast(from);
        edge_to[edge] = @intCast(to);
        edge_weight[edge] = weight;
        if (head_edge[source] < 0) {
            head_edge[source] = @intCast(edge);
        } else {
            next_edge[@intCast(tail_edge[source])] = @intCast(edge);
        }
        tail_edge[source] = @intCast(edge);
    }

    const start: usize = @intCast(start_value);
    const finish: usize = @intCast(finish_value);
    var distance: [MAX_VERTICES]i64 = @splat(INF);
    var deque: [MAX_DEQUE_CAPACITY]usize = @splat(0);
    var deque_head: usize = 0;
    var deque_count: usize = 1;
    distance[start] = 0;
    deque[0] = start;
    while (deque_count > 0) {
        const node = deque[deque_head];
        deque_head = (deque_head + 1) % MAX_DEQUE_CAPACITY;
        deque_count -= 1;
        var edge = head_edge[node];
        while (edge >= 0) {
            const edge_index: usize = @intCast(edge);
            const neighbor = edge_to[edge_index];
            const candidate = distance[node] + edge_weight[edge_index];
            if (candidate < distance[neighbor]) {
                distance[neighbor] = candidate;
                if (edge_weight[edge_index] == 0) {
                    deque_head = (deque_head + MAX_DEQUE_CAPACITY - 1) % MAX_DEQUE_CAPACITY;
                    deque[deque_head] = neighbor;
                } else {
                    deque[(deque_head + deque_count) % MAX_DEQUE_CAPACITY] = neighbor;
                }
                deque_count += 1;
            }
            edge = next_edge[edge_index];
        }
    }
    if (distance[finish] == INF) return -1;
    return distance[finish];
}
