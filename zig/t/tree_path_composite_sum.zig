const max_n: usize = 32;
const max_cells: usize = max_n * max_n;
const max_input: usize = 5 * max_n - 3;
const mod: i64 = 998244353;

fn findRoot(parent: *[max_n]usize, item: usize) usize {
    var node = item;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tree_path_composite_sum(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + n + 4 * (n - 1)) return -1;

    var vertex_value: [max_n]i64 = @splat(0);
    for (0..n) |vertex| {
        vertex_value[vertex] = input[1 + vertex];
        if (vertex_value[vertex] < 0 or vertex_value[vertex] >= mod) return -1;
    }
    var adjacent: [max_cells]bool = @splat(false);
    var multiplier: [max_cells]i64 = @splat(0);
    var addend: [max_cells]i64 = @splat(0);
    var dsu_parent: [max_n]usize = undefined;
    var dsu_size: [max_n]usize = undefined;
    for (0..n) |vertex| {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    var offset = 1 + n;
    for (0..(n - 1)) |_| {
        const u_value = input[offset];
        const v_value = input[offset + 1];
        const b = input[offset + 2];
        const c = input[offset + 3];
        offset += 4;
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or
            u_value == v_value or b < 1 or b >= mod or c < 0 or c >= mod) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        var root_u = findRoot(&dsu_parent, u);
        var root_v = findRoot(&dsu_parent, v);
        if (root_u == root_v) return -1;
        if (dsu_size[root_u] < dsu_size[root_v]) {
            const temporary = root_u;
            root_u = root_v;
            root_v = temporary;
        }
        dsu_parent[root_v] = root_u;
        dsu_size[root_u] += dsu_size[root_v];
        adjacent[u * max_n + v] = true;
        adjacent[v * max_n + u] = true;
        multiplier[u * max_n + v] = b;
        multiplier[v * max_n + u] = b;
        addend[u * max_n + v] = c;
        addend[v * max_n + u] = c;
    }

    var order: [max_n]usize = undefined;
    var stack: [max_n]usize = undefined;
    var parent: [max_n]i64 = undefined;
    for (0..n) |vertex| parent[vertex] = -2;
    parent[0] = -1;
    var top: usize = 1;
    var order_count: usize = 0;
    stack[0] = 0;
    while (top > 0) {
        top -= 1;
        const u = stack[top];
        order[order_count] = u;
        order_count += 1;
        for (0..n) |v| {
            const cell = u * max_n + v;
            if (adjacent[cell] and @as(i64, @intCast(v)) != parent[u]) {
                parent[v] = @intCast(u);
                stack[top] = v;
                top += 1;
            }
        }
    }

    var down_sum: [max_n]i64 = @splat(0);
    var up_sum: [max_n]i64 = @splat(0);
    var answer: [max_n]i64 = @splat(0);
    var down_count: [max_n]usize = @splat(0);
    var up_count: [max_n]usize = @splat(0);
    var position = order_count;
    while (position > 0) {
        position -= 1;
        const u = order[position];
        down_sum[u] = vertex_value[u];
        down_count[u] = 1;
        for (0..n) |v| {
            const cell = u * max_n + v;
            if (adjacent[cell] and parent[v] == @as(i64, @intCast(u))) {
                const contribution = (multiplier[cell] * down_sum[v]
                    + addend[cell] * @as(i64, @intCast(down_count[v]))) % mod;
                down_sum[u] = (down_sum[u] + contribution) % mod;
                down_count[u] += down_count[v];
            }
        }
    }
    for (0..order_count) |order_position| {
        const u = order[order_position];
        var total_sum = vertex_value[u];
        var total_count: usize = 1;
        if (parent[u] >= 0) {
            total_sum = (total_sum + up_sum[u]) % mod;
            total_count += up_count[u];
        }
        for (0..n) |v| {
            const cell = u * max_n + v;
            if (adjacent[cell] and parent[v] == @as(i64, @intCast(u))) {
                total_sum = (total_sum + multiplier[cell] * down_sum[v]
                    + addend[cell] * @as(i64, @intCast(down_count[v]))) % mod;
                total_count += down_count[v];
            }
        }
        answer[u] = total_sum;
        for (0..n) |v| {
            const cell = u * max_n + v;
            if (adjacent[cell] and parent[v] == @as(i64, @intCast(u))) {
                const contribution = (multiplier[cell] * down_sum[v]
                    + addend[cell] * @as(i64, @intCast(down_count[v]))) % mod;
                const outside_sum = (total_sum - contribution + mod) % mod;
                const outside_count = total_count - down_count[v];
                up_sum[v] = (multiplier[cell] * outside_sum
                    + addend[cell] * @as(i64, @intCast(outside_count))) % mod;
                up_count[v] = outside_count;
            }
        }
    }

    const required = 8 * n;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..n) |vertex| storeLe(output, 8 * vertex, answer[vertex]);
    return @intCast(required);
}
