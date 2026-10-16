const MAX_VERTICES: usize = 64;
const MAX_EDGES: i64 = 256;
const MAX_INPUT_LENGTH: usize = 518;
/// Return whether target is reachable from source in an undirected graph.
export fn depth_first_search_iterative(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const n = input[0];
    const m = input[1];
    const source = input[2];
    const target = input[3];
    if (n < 1 or n > @as(i64, @intCast(MAX_VERTICES)) or m < 0 or m > MAX_EDGES
        or source < 0 or source >= n) return -1;
    const edge_count: usize = @intCast(m);
    if (length != 4 + 2 * edge_count) return -1;
    for (0..edge_count) |edge| {
        const left = input[4 + 2 * edge];
        const right = input[5 + 2 * edge];
        if (left < 0 or left >= n or right < 0 or right >= n) return -1;
    }
    var visited: [MAX_VERTICES]bool = @splat(false);
    var pending: [MAX_VERTICES]usize = @splat(0);
    var top: usize = 1;
    pending[0] = @intCast(source);
    visited[pending[0]] = true;
    while (top > 0) {
        top -= 1;
        const current = pending[top];
        if (@as(i64, @intCast(current)) == target) return 1;
        for (0..edge_count) |edge| {
            const left = input[4 + 2 * edge];
            const right = input[5 + 2 * edge];
            var neighbor: i64 = -1;
            if (left == @as(i64, @intCast(current))) {
                neighbor = right;
            } else if (right == @as(i64, @intCast(current))) {
                neighbor = left;
            }
            if (neighbor >= 0) {
                const index: usize = @intCast(neighbor);
                if (!visited[index]) {
                    visited[index] = true;
                    pending[top] = index;
                    top += 1;
                }
            }
        }
    }
    return 0;
}
