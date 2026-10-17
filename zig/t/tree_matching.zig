const MAX_NODES: usize = 64;
const MAX_INPUT_VALUES: usize = 2 + 3 * (MAX_NODES - 1);
const MATRIX_SIZE: usize = MAX_NODES * MAX_NODES;

fn matchingDp(node: usize, parent: isize, count: usize,
    adjacent: *const [MATRIX_SIZE]bool, weights: *const [MATRIX_SIZE]i64,
    visited: *[MAX_NODES]bool, parent_of: *[MAX_NODES]isize,
    without_edge: *[MAX_NODES]i64, with_edge: *[MAX_NODES]i64, reached: *usize) void {
    visited[node] = true;
    parent_of[node] = @intCast(parent);
    reached.* += 1;
    var base: i64 = 0;
    for (0..count) |child| {
        if (adjacent[node * MAX_NODES + child] and @as(isize, @intCast(child)) != parent and !visited[child]) {
            matchingDp(child, @intCast(node), count, adjacent, weights, visited, parent_of,
                without_edge, with_edge, reached);
            base += @max(without_edge[child], with_edge[child]);
        }
    }
    without_edge[node] = base;
    with_edge[node] = 0;
    for (0..count) |child| {
        if (parent_of[child] == @as(isize, @intCast(node))) {
            const child_best = @max(without_edge[child], with_edge[child]);
            const candidate = base - child_best + without_edge[child] + weights[node * MAX_NODES + child];
            with_edge[node] = @max(with_edge[node], candidate);
        }
    }
}

export fn tree_matching(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_INPUT_VALUES) return -1;
    if (values[0] < 1 or values[0] > MAX_NODES) return -1;
    const count: usize = @intCast(values[0]);
    if (length != 2 + 3 * (count - 1) or values[1] < 0 or values[1] >= @as(i64, @intCast(count))) return -1;
    var adjacent = [_]bool{false} ** MATRIX_SIZE;
    var weights = [_]i64{0} ** MATRIX_SIZE;
    for (0..count - 1) |edge| {
        const a_value = values[2 + 3 * edge];
        const b_value = values[3 + 3 * edge];
        const weight = values[4 + 3 * edge];
        if (a_value < 0 or b_value < 0 or a_value >= @as(i64, @intCast(count)) or b_value >= @as(i64, @intCast(count)) or
            a_value == b_value or weight < 0 or weight > 1000) return -1;
        const a: usize = @intCast(a_value);
        const b: usize = @intCast(b_value);
        const ab = a * MAX_NODES + b;
        const ba = b * MAX_NODES + a;
        if (adjacent[ab]) return -1;
        adjacent[ab] = true;
        adjacent[ba] = true;
        weights[ab] = weight;
        weights[ba] = weight;
    }
    var visited = [_]bool{false} ** MAX_NODES;
    var parent_of = [_]isize{-2} ** MAX_NODES;
    var without_edge = [_]i64{0} ** MAX_NODES;
    var with_edge = [_]i64{0} ** MAX_NODES;
    var reached: usize = 0;
    const root: usize = @intCast(values[1]);
    matchingDp(root, -1, count, &adjacent, &weights, &visited, &parent_of,
        &without_edge, &with_edge, &reached);
    if (reached != count) return -1;
    return @max(without_edge[root], with_edge[root]);
}
