const MAX_VERTICES: usize = 6;
const MAX_EDGES: usize = 12;
const MAX_K: usize = 8;
const MAX_INPUT_LENGTH: usize = 41;
const MAX_FRONTIER: usize = 97;

fn writeI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> (8 * byte));
}

export fn k_shortest_walk(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 5 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?;
    const n_value = values[0];
    const m_value = values[1];
    const source_value = values[2];
    const target_value = values[3];
    const k_value = values[4];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_VERTICES)) or
        m_value < 0 or m_value > @as(i64, @intCast(MAX_EDGES)) or
        k_value < 1 or k_value > @as(i64, @intCast(MAX_K)) or
        source_value < 0 or source_value >= n_value or target_value < 0 or target_value >= n_value)
        return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    const source: usize = @intCast(source_value);
    const target: usize = @intCast(target_value);
    const k: usize = @intCast(k_value);
    if (length != 5 + 3 * m) return -1;

    var head = [_]i64{-1} ** MAX_VERTICES;
    var edge_to = [_]i64{0} ** MAX_EDGES;
    var edge_weight = [_]i64{0} ** MAX_EDGES;
    var edge_next = [_]i64{0} ** MAX_EDGES;
    for (0..m) |edge| {
        const u = values[5 + 3 * edge];
        const v = values[6 + 3 * edge];
        const weight = values[7 + 3 * edge];
        if (u < 0 or u >= n_value or v < 0 or v >= n_value or weight < 0 or weight > 1000) return -1;
        const source_vertex: usize = @intCast(u);
        edge_to[edge] = v;
        edge_weight[edge] = weight;
        edge_next[edge] = head[source_vertex];
        head[source_vertex] = @intCast(edge);
    }
    if (output == null or output_capacity < 8 * k) return -2;

    var queue_distance = [_]i64{0} ** MAX_FRONTIER;
    var queue_vertex = [_]i64{0} ** MAX_FRONTIER;
    var queue_order = [_]i64{0} ** MAX_FRONTIER;
    var expanded = [_]i64{0} ** MAX_VERTICES;
    var answers = [_]i64{0} ** MAX_K;
    var queue_count: usize = 1;
    var answer_count: usize = 0;
    var next_order: i64 = 1;
    queue_distance[0] = 0;
    queue_vertex[0] = @intCast(source);
    queue_order[0] = 0;

    while (queue_count > 0 and answer_count < k) {
        const distance = queue_distance[0];
        const vertex: usize = @intCast(queue_vertex[0]);
        for (1..queue_count) |slot| {
            queue_distance[slot - 1] = queue_distance[slot];
            queue_vertex[slot - 1] = queue_vertex[slot];
            queue_order[slot - 1] = queue_order[slot];
        }
        queue_count -= 1;
        if (expanded[vertex] >= @as(i64, @intCast(k))) continue;
        expanded[vertex] += 1;
        if (vertex == target) {
            answers[answer_count] = distance;
            answer_count += 1;
            if (answer_count == k) break;
        }
        var edge = head[vertex];
        while (edge >= 0) {
            const edge_index: usize = @intCast(edge);
            const candidate_distance = distance + edge_weight[edge_index];
            const candidate_vertex = edge_to[edge_index];
            const candidate_order = next_order;
            next_order += 1;
            var position = queue_count;
            while (position > 0 and
                (queue_distance[position - 1] > candidate_distance or
                 (queue_distance[position - 1] == candidate_distance and queue_order[position - 1] > candidate_order))) {
                queue_distance[position] = queue_distance[position - 1];
                queue_vertex[position] = queue_vertex[position - 1];
                queue_order[position] = queue_order[position - 1];
                position -= 1;
            }
            queue_distance[position] = candidate_distance;
            queue_vertex[position] = candidate_vertex;
            queue_order[position] = candidate_order;
            queue_count += 1;
            edge = edge_next[edge_index];
        }
    }
    while (answer_count < k) {
        answers[answer_count] = -1;
        answer_count += 1;
    }
    const bytes = output.?;
    for (0..k) |index| writeI64(bytes, 8 * index, answers[index]);
    return @intCast(8 * k);
}
