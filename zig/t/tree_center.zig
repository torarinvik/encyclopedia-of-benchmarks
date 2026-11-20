const max_n: usize = 64;
const max_input_length: usize = 1 + 2 * (max_n - 1);
const matrix_cells: usize = max_n * max_n;

fn findRoot(parent: []usize, item: usize) usize {
    var node = item;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tree_center(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > max_input_length) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + 2 * (n - 1)) return -1;

    var adjacency: [matrix_cells]usize = @splat(0);
    var adjacency_count: [max_n]usize = @splat(0);
    var degree: [max_n]usize = @splat(0);
    var parent: [max_n]usize = undefined;
    var component_size: [max_n]usize = undefined;
    for (0..n) |vertex| {
        parent[vertex] = vertex;
        component_size[vertex] = 1;
    }
    for (0..(n - 1)) |edge| {
        const offset = 1 + 2 * edge;
        const left_value = input[offset];
        const right_value = input[offset + 1];
        if (left_value < 0 or left_value >= n_value or right_value < 0 or
            right_value >= n_value or left_value == right_value) return -1;
        const left: usize = @intCast(left_value);
        const right: usize = @intCast(right_value);
        var root_left = findRoot(parent[0..], left);
        var root_right = findRoot(parent[0..], right);
        if (root_left == root_right) return -1;
        if (component_size[root_left] < component_size[root_right]) {
            const temporary = root_left;
            root_left = root_right;
            root_right = temporary;
        }
        parent[root_right] = root_left;
        component_size[root_left] += component_size[root_right];
        adjacency[left * max_n + adjacency_count[left]] = right;
        adjacency_count[left] += 1;
        adjacency[right * max_n + adjacency_count[right]] = left;
        adjacency_count[right] += 1;
        degree[left] += 1;
        degree[right] += 1;
    }
    if (n > 1 and component_size[findRoot(parent[0..], 0)] != n) return -1;

    var active: [max_n]bool = @splat(false);
    var leaves: [max_n]usize = undefined;
    var leaf_count: usize = 0;
    for (0..n) |vertex| {
        active[vertex] = true;
        if (degree[vertex] <= 1) {
            leaves[leaf_count] = vertex;
            leaf_count += 1;
        }
    }
    var remaining = n;
    while (remaining > 2) {
        for (0..leaf_count) |index| active[leaves[index]] = false;
        remaining -= leaf_count;
        for (0..leaf_count) |index| {
            const leaf = leaves[index];
            for (0..adjacency_count[leaf]) |edge| {
                const neighbor = adjacency[leaf * max_n + edge];
                if (active[neighbor]) degree[neighbor] -= 1;
            }
        }
        if (remaining <= 2) break;
        leaf_count = 0;
        for (0..n) |vertex| {
            if (active[vertex] and degree[vertex] == 1) {
                leaves[leaf_count] = vertex;
                leaf_count += 1;
            }
        }
    }

    var centers: [2]i64 = undefined;
    var center_count: usize = 0;
    for (0..n) |vertex| {
        if (active[vertex]) {
            centers[center_count] = @intCast(vertex);
            center_count += 1;
        }
    }
    const required = 8 * center_count;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..center_count) |index| storeI64Le(output, 8 * index, centers[index]);
    return @intCast(required);
}
