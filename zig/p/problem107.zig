const MAX_VERTICES: usize = 40;
const MAX_EDGE_WEIGHT: i64 = 999;

fn edgeWeight(input: [*c]const i64, left: usize, right: usize) i64 {
    if (left == right) return -1;
    const row = @max(left, right);
    const column = @min(left, right);
    return input[1 + row * (row - 1) / 2 + column];
}

pub export fn problem107(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1) return -1;
    const vertex_count_value = input[0];
    if (vertex_count_value < 1 or vertex_count_value > MAX_VERTICES) return -1;
    const vertex_count: usize = @intCast(vertex_count_value);
    if (length != 1 + vertex_count * (vertex_count - 1) / 2) return -1;

    var total_weight: i64 = 0;
    for (1..length) |index| {
        const weight = input[index];
        if (weight < -1 or weight > MAX_EDGE_WEIGHT) return -1;
        if (weight >= 0) total_weight += weight;
    }
    var selected = [_]bool{false} ** MAX_VERTICES;
    var best_weight = [_]i64{MAX_EDGE_WEIGHT + 1} ** MAX_VERTICES;
    best_weight[0] = 0;
    var tree_weight: i64 = 0;
    for (0..vertex_count) |_| {
        var next_vertex = vertex_count;
        var next_weight: i64 = MAX_EDGE_WEIGHT + 1;
        for (0..vertex_count) |vertex| {
            if (!selected[vertex] and best_weight[vertex] < next_weight) {
                next_vertex = vertex;
                next_weight = best_weight[vertex];
            }
        }
        if (next_vertex == vertex_count) return -1;
        selected[next_vertex] = true;
        tree_weight += next_weight;
        for (0..vertex_count) |vertex| {
            if (selected[vertex]) continue;
            const weight = edgeWeight(input, next_vertex, vertex);
            if (weight >= 0 and weight < best_weight[vertex]) best_weight[vertex] = weight;
        }
    }
    return total_weight - tree_weight;
}
