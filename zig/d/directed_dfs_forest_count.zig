const MAX_EDGE_COUNT: usize = 64;
const MAX_VERTEX_ID: i64 = 63;
const MAX_NODE_COUNT: usize = 128;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_EDGE_COUNT;

fn findLastNode(label: i64, labels: [*]const i64, node_count: usize) usize {
    var found: usize = MAX_NODE_COUNT;
    for (0..node_count) |node| {
        if (labels[node] == label) found = node;
    }
    return found;
}

fn visit(current: usize, edge_count: usize, edge_starts: [*]const usize,
    edge_ends: [*]const usize, visited: *[MAX_NODE_COUNT]bool) void {
    visited.*[current] = true;
    for (0..edge_count) |edge| {
        const destination = edge_ends[edge];
        if (edge_starts[edge] == current and !visited.*[destination])
            visit(destination, edge_count, edge_starts, edge_ends, visited);
    }
}

export fn directed_dfs_forest_count(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH + 1) return -1;
    const edge_count_value = input[0];
    if (edge_count_value < 0 or edge_count_value > @as(i64, @intCast(MAX_EDGE_COUNT))) return -1;
    const edge_count: usize = @intCast(edge_count_value);
    if (length != 1 + 2 * edge_count) return -1;

    var labels: [MAX_NODE_COUNT]i64 = @splat(0);
    var edge_starts: [MAX_EDGE_COUNT]usize = @splat(0);
    var edge_ends: [MAX_EDGE_COUNT]usize = @splat(0);
    var node_count: usize = 0;
    for (0..edge_count) |edge| {
        const start_label = input[1 + 2 * edge];
        const end_label = input[2 + 2 * edge];
        if (start_label < 0 or start_label > MAX_VERTEX_ID
            or end_label < 0 or end_label > MAX_VERTEX_ID) return -1;

        var start = findLastNode(start_label, &labels[0], node_count);
        var ending: usize = MAX_NODE_COUNT;
        if (start_label == end_label) {
            if (start == MAX_NODE_COUNT) {
                start = node_count;
                labels[node_count] = start_label;
                node_count += 1;
            }
            ending = node_count;
            labels[node_count] = end_label;
            node_count += 1;
        } else {
            ending = findLastNode(end_label, &labels[0], node_count);
            if (start == MAX_NODE_COUNT) {
                start = node_count;
                labels[node_count] = start_label;
                node_count += 1;
            }
            if (ending == MAX_NODE_COUNT) {
                ending = node_count;
                labels[node_count] = end_label;
                node_count += 1;
            }
        }
        edge_starts[edge] = start;
        edge_ends[edge] = ending;
    }

    var marked: [MAX_NODE_COUNT]bool = @splat(false);
    var roots: i64 = 0;
    for (0..node_count) |root| {
        if (marked[root]) continue;
        var visited: [MAX_NODE_COUNT]bool = @splat(false);
        visit(root, edge_count, &edge_starts[0], &edge_ends[0], &visited);
        for (0..node_count) |node| {
            if (visited[node]) marked[node] = true;
        }
        roots += 1;
    }
    return roots;
}
