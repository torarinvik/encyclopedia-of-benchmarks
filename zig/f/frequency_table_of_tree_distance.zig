const max_n: usize = 64;
const max_input_values: usize = 1 + 2 * (max_n - 1);

const WalkItem = struct {
    vertex: usize,
    parent: usize,
    depth: usize,
};

fn findRoot(parent: []usize, item: usize) usize {
    var node = item;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn solveComponent(n: usize, adjacent: []const bool, removed: []bool,
    answer: []i64, start: usize) void {
    var order: [max_n]usize = undefined;
    var parent: [max_n]usize = undefined;
    var subtree: [max_n]usize = @splat(0);
    var stack: [max_n]usize = undefined;
    var order_count: usize = 0;
    var top: usize = 1;
    stack[0] = start;
    parent[start] = start;
    subtree[start] = 1;
    order[order_count] = start;
    order_count += 1;
    while (top > 0) {
        top -= 1;
        const vertex = stack[top];
        for (0..n) |neighbor| {
            if (!adjacent[vertex * max_n + neighbor] or removed[neighbor] or neighbor == parent[vertex]) continue;
            parent[neighbor] = vertex;
            subtree[neighbor] = 1;
            order[order_count] = neighbor;
            order_count += 1;
            stack[top] = neighbor;
            top += 1;
        }
    }
    var position = order_count;
    while (position > 1) {
        position -= 1;
        const vertex = order[position];
        subtree[parent[vertex]] += subtree[vertex];
    }

    var centroid: usize = max_n;
    for (0..order_count) |index| {
        const vertex = order[index];
        var largest_part = order_count - subtree[vertex];
        for (0..n) |neighbor| {
            if (adjacent[vertex * max_n + neighbor] and !removed[neighbor] and
                parent[neighbor] == vertex and subtree[neighbor] > largest_part)
                largest_part = subtree[neighbor];
        }
        if (2 * largest_part <= order_count and (centroid == max_n or vertex < centroid))
            centroid = vertex;
    }

    var frequency: [max_n]i64 = @splat(0);
    var frequency_max: usize = 0;
    frequency[0] = 1;
    removed[centroid] = true;
    for (0..n) |child| {
        if (!adjacent[centroid * max_n + child] or removed[child]) continue;
        var local_frequency: [max_n]usize = @splat(0);
        var walk: [max_n]WalkItem = undefined;
        var local_max: usize = 0;
        var walk_top: usize = 1;
        walk[0] = .{ .vertex = child, .parent = centroid, .depth = 1 };
        while (walk_top > 0) {
            walk_top -= 1;
            const item = walk[walk_top];
            local_frequency[item.depth] += 1;
            local_max = @max(local_max, item.depth);
            for (0..n) |neighbor| {
                if (adjacent[item.vertex * max_n + neighbor] and !removed[neighbor] and neighbor != item.parent) {
                    walk[walk_top] = .{ .vertex = neighbor, .parent = item.vertex, .depth = item.depth + 1 };
                    walk_top += 1;
                }
            }
        }
        for (1..(local_max + 1)) |depth| {
            for (0..(frequency_max + 1)) |other| {
                if (depth + other < n)
                    answer[depth + other] += @as(i64, @intCast(local_frequency[depth])) * frequency[other];
            }
        }
        for (1..(local_max + 1)) |depth|
            frequency[depth] += @intCast(local_frequency[depth]);
        frequency_max = @max(frequency_max, local_max);
    }

    for (0..n) |child|
        if (adjacent[centroid * max_n + child] and !removed[child])
            solveComponent(n, adjacent, removed, answer, child);
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn frequency_table_of_tree_distance(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > max_input_values) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > max_n) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + 2 * (n - 1)) return -1;

    var adjacent: [max_n * max_n]bool = @splat(false);
    var dsu_parent: [max_n]usize = undefined;
    var dsu_size: [max_n]usize = undefined;
    for (0..n) |vertex| {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    for (0..(n - 1)) |edge| {
        const offset = 1 + 2 * edge;
        const left_value = input[offset];
        const right_value = input[offset + 1];
        if (left_value < 0 or left_value >= n_value or right_value < 0 or
            right_value >= n_value or left_value == right_value) return -1;
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
    }

    var removed: [max_n]bool = @splat(false);
    var answer: [max_n]i64 = @splat(0);
    solveComponent(n, adjacent[0..], removed[0..], answer[0..], 0);
    const required = 8 * (n - 1);
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (1..n) |distance| storeI64Le(output, 8 * (distance - 1), answer[distance]);
    return @intCast(required);
}
