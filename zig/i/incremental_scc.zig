const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 32;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES;

export fn incremental_scc(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_VERTICES)) or
        values[1] < 0 or values[1] > @as(i64, @intCast(MAX_EDGES))) return -1;
    const vertex_count: usize = @intCast(values[0]);
    const edge_count: usize = @intCast(values[1]);
    if (length != 2 + 2 * edge_count) return -1;

    var sources: [MAX_EDGES]usize = undefined;
    var destinations: [MAX_EDGES]usize = undefined;
    for (0..edge_count) |edge| {
        const source = values[2 + 2 * edge];
        const destination = values[3 + 2 * edge];
        if (source < 0 or destination < 0 or source >= @as(i64, @intCast(vertex_count)) or
            destination >= @as(i64, @intCast(vertex_count))) return -1;
        sources[edge] = @intCast(source);
        destinations[edge] = @intCast(destination);
    }

    var reachable = [_][MAX_VERTICES]bool{[_]bool{false} ** MAX_VERTICES} ** MAX_VERTICES;
    for (0..vertex_count) |vertex| reachable[vertex][vertex] = true;
    var checksum: i64 = 0;
    for (0..edge_count) |edge| {
        const source = sources[edge];
        const destination = destinations[edge];
        var predecessors: [MAX_VERTICES]bool = undefined;
        var successors: [MAX_VERTICES]bool = undefined;
        for (0..vertex_count) |vertex| {
            predecessors[vertex] = reachable[vertex][source];
            successors[vertex] = reachable[destination][vertex];
        }
        for (0..vertex_count) |first| {
            for (0..vertex_count) |second| {
                if (predecessors[first] and successors[second]) reachable[first][second] = true;
            }
        }

        var assigned = [_]bool{false} ** MAX_VERTICES;
        var component_count: i64 = 0;
        for (0..vertex_count) |first| {
            if (assigned[first]) continue;
            component_count += 1;
            for (first..vertex_count) |vertex| {
                if (reachable[first][vertex] and reachable[vertex][first]) assigned[vertex] = true;
            }
        }
        checksum += @as(i64, @intCast(edge + 1)) * component_count;
    }
    return checksum;
}
