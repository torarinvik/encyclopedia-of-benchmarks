const max_n: usize = 64;
const max_input_values: usize = 1 + 3 * (max_n - 1);
const max_output_values: usize = 2 + max_n;
const matrix_cells: usize = max_n * max_n;

fn findRoot(parent: []usize, item: usize) usize {
    var node = item;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn traverse(n: usize, start: usize, adjacent: []const bool, weights: []const i64,
    distance: []i64, path_parent: []i64) void {
    var stack: [max_n]usize = undefined;
    for (0..n) |vertex| {
        distance[vertex] = -1;
        path_parent[vertex] = -1;
    }
    var top: usize = 1;
    stack[0] = start;
    distance[start] = 0;
    while (top > 0) {
        top -= 1;
        const current = stack[top];
        for (0..n) |neighbor| {
            const cell = current * max_n + neighbor;
            if (adjacent[cell] and distance[neighbor] < 0) {
                distance[neighbor] = distance[current] + weights[cell];
                path_parent[neighbor] = @intCast(current);
                stack[top] = neighbor;
                top += 1;
            }
        }
    }
}

fn farthest(n: usize, distance: []const i64) usize {
    var best: usize = 0;
    for (1..n) |vertex| {
        if (distance[vertex] > distance[best] or
            (distance[vertex] == distance[best] and vertex < best)) best = vertex;
    }
    return best;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tree_diameter(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > max_input_values) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > max_n) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + 3 * (n - 1)) return -1;

    var adjacent: [matrix_cells]bool = @splat(false);
    var weights: [matrix_cells]i64 = @splat(0);
    var dsu_parent: [max_n]usize = undefined;
    var dsu_size: [max_n]usize = undefined;
    for (0..n) |vertex| {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    for (0..(n - 1)) |edge| {
        const offset = 1 + 3 * edge;
        const left_value = input[offset];
        const right_value = input[offset + 1];
        const edge_weight = input[offset + 2];
        if (left_value < 0 or left_value >= n_value or right_value < 0 or
            right_value >= n_value or left_value == right_value or
            edge_weight < 1 or edge_weight > 1_000_000_000) return -1;
        const left: usize = @intCast(left_value);
        const right: usize = @intCast(right_value);
        var root_left = findRoot(dsu_parent[0..], left);
        var root_right = findRoot(dsu_parent[0..], right);
        if (root_left == root_right) return -1;
        if (dsu_size[root_left] < dsu_size[root_right]) {
            const temporary = root_left;
            root_left = root_right;
            root_right = temporary;
        }
        dsu_parent[root_right] = root_left;
        dsu_size[root_left] += dsu_size[root_right];
        adjacent[left * max_n + right] = true;
        adjacent[right * max_n + left] = true;
        weights[left * max_n + right] = edge_weight;
        weights[right * max_n + left] = edge_weight;
    }

    var distance: [max_n]i64 = undefined;
    var path_parent: [max_n]i64 = undefined;
    traverse(n, 0, adjacent[0..], weights[0..], distance[0..], path_parent[0..]);
    const first_endpoint = farthest(n, distance[0..]);
    traverse(n, first_endpoint, adjacent[0..], weights[0..], distance[0..], path_parent[0..]);
    const second_endpoint = farthest(n, distance[0..]);
    var reverse_path: [max_n]usize = undefined;
    var path_length: usize = 0;
    var current: i64 = @intCast(second_endpoint);
    while (current >= 0) {
        reverse_path[path_length] = @intCast(current);
        path_length += 1;
        if (@as(usize, @intCast(current)) == first_endpoint) break;
        current = path_parent[@intCast(current)];
    }

    var staged: [max_output_values]i64 = undefined;
    var used: usize = 0;
    staged[used] = distance[second_endpoint];
    used += 1;
    staged[used] = @intCast(path_length);
    used += 1;
    for (0..path_length) |position| {
        staged[used] = @intCast(reverse_path[path_length - 1 - position]);
        used += 1;
    }
    const required = 8 * used;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..used) |index| storeI64Le(output, 8 * index, staged[index]);
    return @intCast(required);
}
