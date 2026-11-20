const max_n: usize = 64;
const max_input_length: usize = 1 + 2 * (max_n - 1);

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tree_center_rerooting_dp(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > max_input_length) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + 2 * (n - 1)) return -1;

    var adjacency: [max_n][max_n]usize = @splat(@splat(0));
    var degree: [max_n]usize = @splat(0);
    for (0..(n - 1)) |edge| {
        const offset = 1 + 2 * edge;
        const left_value = input[offset];
        const right_value = input[offset + 1];
        if (left_value < 0 or left_value >= n_value or right_value < 0 or
            right_value >= n_value or left_value == right_value) return -1;
        const left: usize = @intCast(left_value);
        const right: usize = @intCast(right_value);
        adjacency[left][degree[left]] = right;
        degree[left] += 1;
        adjacency[right][degree[right]] = left;
        degree[right] += 1;
    }

    var parent: [max_n]usize = @splat(max_n);
    var order: [max_n]usize = @splat(0);
    parent[0] = max_n + 1;
    var order_count: usize = 1;
    var position: usize = 0;
    while (position < order_count) : (position += 1) {
        const vertex = order[position];
        for (0..degree[vertex]) |edge| {
            const child = adjacency[vertex][edge];
            if (child == parent[vertex]) continue;
            if (parent[child] != max_n) return -1;
            parent[child] = vertex;
            order[order_count] = child;
            order_count += 1;
        }
    }
    if (order_count != n) return -1;

    var down: [max_n]usize = @splat(0);
    var best: [max_n]usize = @splat(0);
    var second: [max_n]usize = @splat(0);
    var best_child: [max_n]usize = @splat(max_n);
    position = n;
    while (position > 0) {
        position -= 1;
        const vertex = order[position];
        for (0..degree[vertex]) |edge| {
            const child = adjacency[vertex][edge];
            if (parent[child] != vertex) continue;
            const branch = down[child] + 1;
            if (branch > best[vertex]) {
                second[vertex] = best[vertex];
                best[vertex] = branch;
                best_child[vertex] = child;
            } else if (branch > second[vertex]) {
                second[vertex] = branch;
            }
        }
        down[vertex] = best[vertex];
    }

    var outside: [max_n]isize = @splat(-1);
    for (0..n) |i| {
        const vertex = order[i];
        for (0..degree[vertex]) |edge| {
            const child = adjacency[vertex][edge];
            if (parent[child] != vertex) continue;
            const sibling = if (best_child[vertex] == child) second[vertex] else best[vertex];
            const sibling_signed: isize = @intCast(sibling);
            outside[child] = @max(outside[vertex], sibling_signed) + 1;
        }
    }

    var radius: usize = max_n;
    for (0..n) |vertex| {
        const eccentricity = @max(down[vertex], @as(usize, @intCast(@max(0, outside[vertex]))));
        radius = @min(radius, eccentricity);
    }
    var centers: [2]i64 = undefined;
    var center_count: usize = 0;
    for (0..n) |vertex| {
        const eccentricity = @max(down[vertex], @as(usize, @intCast(@max(0, outside[vertex]))));
        if (eccentricity == radius) {
            centers[center_count] = @intCast(vertex);
            center_count += 1;
        }
    }
    const required = center_count * 8;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..center_count) |i| storeI64Le(output, i * 8, centers[i]);
    return @intCast(required);
}
