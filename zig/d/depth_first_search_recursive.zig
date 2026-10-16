/// Recursive reachability search in a bounded undirected graph.
const MAX_VERTICES: usize = 64;
const MAX_EDGES: i64 = 256;
const MAX_INPUT_LENGTH: usize = 518;
const ADJACENCY_CAPACITY: usize = MAX_VERTICES * MAX_VERTICES;

fn reachable(adjacency: [*]const usize, degree: [*]const usize, current: usize,
              target: i64, visited: *[MAX_VERTICES]bool) bool {
    if (@as(i64, @intCast(current)) == target) return true;
    visited.*[current] = true;
    for (0..degree[current]) |position| {
        const neighbor = adjacency[current * MAX_VERTICES + position];
        if (!visited.*[neighbor] and reachable(adjacency, degree, neighbor, target, visited)) return true;
    }
    return false;
}

export fn depth_first_search_recursive(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const vertex_count = input[0];
    const edge_count_value = input[1];
    const source = input[2];
    const target = input[3];
    if (vertex_count < 1 or vertex_count > MAX_VERTICES or edge_count_value < 0
        or edge_count_value > MAX_EDGES or source < 0 or source >= vertex_count) return -1;
    const edge_count: usize = @intCast(edge_count_value);
    if (length != 4 + 2 * edge_count) return -1;
    for (0..edge_count) |edge| {
        const left = input[4 + 2 * edge];
        const right = input[5 + 2 * edge];
        if (left < 0 or left >= vertex_count or right < 0 or right >= vertex_count) return -1;
    }

    var adjacency: [ADJACENCY_CAPACITY]usize = @splat(0);
    var degree: [MAX_VERTICES]usize = @splat(0);
    var seen: [MAX_VERTICES]u64 = @splat(0);
    for (0..edge_count) |edge| {
        const left: usize = @intCast(input[4 + 2 * edge]);
        const right: usize = @intCast(input[5 + 2 * edge]);
        const right_bit = @as(u64, 1) << @intCast(right);
        if ((seen[left] & right_bit) == 0) {
            seen[left] |= right_bit;
            adjacency[left * MAX_VERTICES + degree[left]] = right;
            degree[left] += 1;
        }
        const left_bit = @as(u64, 1) << @intCast(left);
        if ((seen[right] & left_bit) == 0) {
            seen[right] |= left_bit;
            adjacency[right * MAX_VERTICES + degree[right]] = left;
            degree[right] += 1;
        }
    }
    var visited: [MAX_VERTICES]bool = @splat(false);
    return if (reachable(&adjacency[0], &degree[0], @intCast(source), target, &visited)) 1 else 0;
}
