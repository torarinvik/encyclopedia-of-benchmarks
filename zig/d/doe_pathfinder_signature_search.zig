const MAX_NODES: i64 = 10;
const MAX_EDGES: i64 = 100;
const MAX_SIGNATURE_LENGTH: i64 = 4;
const MAX_LABEL: i64 = 7;

fn searchLeg(values: [*c]const i64, edge_count: usize, labels_start: usize,
    signature_start: usize, signature_length: usize, node: usize,
    signature_index: usize, visited: *u16) bool {
    const bit: u16 = @as(u16, 1) << @as(u4, @intCast(node));
    if ((visited.* & bit) != 0) return false;
    visited.* |= bit;
    const target_label = values[signature_start + signature_index];

    for (0..edge_count) |edge| {
        if (@as(usize, @intCast(values[3 + 2 * edge])) != node) continue;
        const target: usize = @intCast(values[4 + 2 * edge]);
        if (values[labels_start + target] != target_label) continue;
        if (signature_index + 1 == signature_length) return true;
        var next_visited: u16 = 0;
        if (searchLeg(values, edge_count, labels_start, signature_start, signature_length,
            target, signature_index + 1, &next_visited)) return true;
    }

    for (0..edge_count) |edge| {
        if (@as(usize, @intCast(values[3 + 2 * edge])) != node) continue;
        const target: usize = @intCast(values[4 + 2 * edge]);
        if (searchLeg(values, edge_count, labels_start, signature_start, signature_length,
            target, signature_index, visited)) return true;
    }
    return false;
}

export fn doe_pathfinder_signature_search(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 3) return -2;
    if (values[0] < 1 or values[0] > MAX_NODES or values[1] < 0 or values[1] > MAX_EDGES or
        values[2] < 2 or values[2] > MAX_SIGNATURE_LENGTH) return -2;
    const node_count: usize = @intCast(values[0]);
    const edge_count: usize = @intCast(values[1]);
    const signature_length: usize = @intCast(values[2]);
    if (edge_count > node_count * node_count ||
        length != 3 + 2 * edge_count + node_count + signature_length) return -2;

    for (0..edge_count) |edge| {
        const from = values[3 + 2 * edge];
        const to = values[4 + 2 * edge];
        if (from < 0 or from >= @as(i64, @intCast(node_count)) or
            to < 0 or to >= @as(i64, @intCast(node_count))) return -2;
        for (0..edge) |previous| {
            if (values[3 + 2 * previous] == from and values[4 + 2 * previous] == to) return -2;
        }
    }
    const labels_start = 3 + 2 * edge_count;
    const signature_start = labels_start + node_count;
    for (0..node_count) |node| {
        if (values[labels_start + node] < -1 or values[labels_start + node] > MAX_LABEL) return -2;
    }
    for (0..signature_length) |index| {
        if (values[signature_start + index] < 0 or values[signature_start + index] > MAX_LABEL) return -2;
    }

    const first_label = values[signature_start];
    for (0..node_count) |node| {
        if (values[labels_start + node] == first_label) {
            var visited: u16 = 0;
            if (searchLeg(values, edge_count, labels_start, signature_start, signature_length,
                node, 1, &visited)) return 1;
        }
    }
    return 0;
}
