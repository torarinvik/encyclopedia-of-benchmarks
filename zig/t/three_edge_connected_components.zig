const max_vertices: usize = 8;
const max_edges: usize = 32;
const max_input_length: usize = 2 + 2 * max_edges;

const Edge = struct { from: usize = 0, to: usize = 0 };

fn refineForRemoval(
    edges: *const [max_edges]Edge,
    vertex_count: usize,
    edge_count: usize,
    removed_first: isize,
    removed_second: isize,
    same: *[max_vertices][max_vertices]bool,
) void {
    var component = [_]i32{-1} ** max_vertices;
    var next_component: i32 = 0;
    var queue: [max_vertices]usize = undefined;
    for (0..vertex_count) |start| {
        if (component[start] >= 0) continue;
        var head: usize = 0;
        var tail: usize = 0;
        component[start] = next_component;
        queue[tail] = start;
        tail += 1;
        while (head < tail) {
            const vertex = queue[head];
            head += 1;
            for (0..edge_count) |edge_id| {
                if (@as(isize, @intCast(edge_id)) == removed_first or @as(isize, @intCast(edge_id)) == removed_second) continue;
                const edge = edges[edge_id];
                var neighbor: ?usize = null;
                if (edge.from == vertex) {
                    neighbor = edge.to;
                } else if (edge.to == vertex) {
                    neighbor = edge.from;
                }
                if (neighbor) |other| {
                    if (component[other] < 0) {
                        component[other] = next_component;
                        queue[tail] = other;
                        tail += 1;
                    }
                }
            }
        }
        next_component += 1;
    }
    for (0..vertex_count) |first| {
        for (first + 1..vertex_count) |second| {
            if (component[first] != component[second]) {
                same[first][second] = false;
                same[second][first] = false;
            }
        }
    }
}

export fn three_edge_connected_components(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > max_input_length) return -1;
    const packed = values.?;
    if (packed[0] < 1 or packed[0] > @as(i64, @intCast(max_vertices))
        or packed[1] < 0 or packed[1] > @as(i64, @intCast(max_edges))) return -1;
    const vertex_count: usize = @intCast(packed[0]);
    const edge_count: usize = @intCast(packed[1]);
    if (length != 2 + 2 * edge_count) return -1;

    var edges: [max_edges]Edge = undefined;
    for (0..edge_count) |edge_id| {
        const from = packed[2 + 2 * edge_id];
        const to = packed[3 + 2 * edge_id];
        if (from < 0 or from >= @as(i64, @intCast(vertex_count))
            or to < 0 or to >= @as(i64, @intCast(vertex_count))) return -1;
        edges[edge_id] = .{ .from = @intCast(from), .to = @intCast(to) };
    }

    var same = [_][max_vertices]bool{[_]bool{true} ** max_vertices} ** max_vertices;
    refineForRemoval(&edges, vertex_count, edge_count, -1, -1, &same);
    for (0..edge_count) |first| {
        refineForRemoval(&edges, vertex_count, edge_count, @intCast(first), -1, &same);
        for (first + 1..edge_count) |second| {
            refineForRemoval(&edges, vertex_count, edge_count,
                @intCast(first), @intCast(second), &same);
        }
    }

    var labels = [_]i64{-1} ** max_vertices;
    var next_label: i64 = 0;
    for (0..vertex_count) |first| {
        if (labels[first] >= 0) continue;
        for (first..vertex_count) |vertex| {
            if (labels[vertex] < 0 and same[first][vertex]) labels[vertex] = next_label;
        }
        next_label += 1;
    }
    var encoded: i64 = 0;
    var place: i64 = 1;
    for (0..vertex_count) |vertex| {
        encoded += labels[vertex] * place;
        place *= 8;
    }
    return encoded;
}
