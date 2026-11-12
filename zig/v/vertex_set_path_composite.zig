const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MODULUS: i64 = 998244353;
const MAX_INPUT_VALUES: usize = 4 * MAX_N + 4 * MAX_Q;

const Affine = struct { a: i64 = 1, b: i64 = 0 };
const Aggregate = struct { forward: Affine = .{}, backward: Affine = .{} };

fn compose(after: Affine, before: Affine) Affine {
    return .{
        .a = @mod(after.a * before.a, MODULUS),
        .b = @mod(after.a * before.b + after.b, MODULUS),
    };
}

fn combine(left: Aggregate, right: Aggregate) Aggregate {
    return .{
        .forward = compose(right.forward, left.forward),
        .backward = compose(left.backward, right.backward),
    };
}

fn identityAggregate() Aggregate {
    return .{};
}

fn findRoot(parent: *[MAX_N]usize, item: usize) usize {
    var node = item;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn updateLeaf(tree: *[2 * MAX_N]Aggregate, base: usize, position: usize, value: Affine) void {
    var node = base + position;
    tree[node] = .{ .forward = value, .backward = value };
    while (node > 1) {
        node >>= 1;
        tree[node] = combine(tree[node * 2], tree[node * 2 + 1]);
    }
}

fn rangeQuery(tree: *const [2 * MAX_N]Aggregate, base: usize, left_value: usize, right_value: usize) Aggregate {
    var prefix = identityAggregate();
    var suffix = identityAggregate();
    var left = left_value + base;
    var right = right_value + base;
    while (left < right) {
        if (left & 1 != 0) {
            prefix = combine(prefix, tree[left]);
            left += 1;
        }
        if (right & 1 != 0) {
            right -= 1;
            suffix = combine(tree[right], suffix);
        }
        left >>= 1;
        right >>= 1;
    }
    return combine(prefix, suffix);
}

fn pathComposition(tree: *const [2 * MAX_N]Aggregate, base: usize,
    parent: *const [MAX_N]usize, depth: *const [MAX_N]usize,
    head: *const [MAX_N]usize, position: *const [MAX_N]usize,
    from_value: usize, to_value: usize) Affine {
    var left = Affine{};
    var right = Affine{};
    var from = from_value;
    var to = to_value;
    while (head[from] != head[to]) {
        if (depth[head[from]] >= depth[head[to]]) {
            const part = rangeQuery(tree, base, position[head[from]], position[from] + 1);
            left = compose(part.backward, left);
            from = parent[head[from]];
        } else {
            const part = rangeQuery(tree, base, position[head[to]], position[to] + 1);
            right = compose(right, part.forward);
            to = parent[head[to]];
        }
    }
    if (depth[from] >= depth[to]) {
        const part = rangeQuery(tree, base, position[to], position[from] + 1);
        left = compose(part.backward, left);
    } else {
        const part = rangeQuery(tree, base, position[from], position[to] + 1);
        right = compose(right, part.forward);
    }
    return compose(right, left);
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn vertex_set_path_composite(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 8 or length > MAX_INPUT_VALUES) return -1;
    const packed = input[0..length];
    const nv = packed[0];
    const qv = packed[1];
    if (nv < 1 or nv > MAX_N or qv < 1 or qv > MAX_Q) return -1;
    const n: usize = @intCast(nv);
    const q: usize = @intCast(qv);
    if (length != 4 * n + 4 * q) return -1;

    var values: [MAX_N]Affine = @splat(.{});
    for (0..n) |vertex| {
        const a = packed[2 + 2 * vertex];
        const b = packed[3 + 2 * vertex];
        if (a < 1 or a >= MODULUS or b < 0 or b >= MODULUS) return -1;
        values[vertex] = .{ .a = a, .b = b };
    }

    var adjacent: [MAX_N][MAX_N]bool = @splat(@splat(false));
    var dsu_parent: [MAX_N]usize = @splat(0);
    var dsu_size: [MAX_N]usize = @splat(0);
    for (0..n) |vertex| {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    const edge_start = 2 + 2 * n;
    for (0..(n - 1)) |edge| {
        const offset = edge_start + 2 * edge;
        const left_value = packed[offset];
        const right_value = packed[offset + 1];
        if (left_value < 0 or left_value >= nv or right_value < 0 or right_value >= nv or left_value == right_value) return -1;
        const left: usize = @intCast(left_value);
        const right: usize = @intCast(right_value);
        var root_left = findRoot(&dsu_parent, left);
        var root_right = findRoot(&dsu_parent, right);
        if (root_left == root_right) return -1;
        if (dsu_size[root_left] < dsu_size[root_right]) {
            const temporary = root_left;
            root_left = root_right;
            root_right = temporary;
        }
        dsu_parent[root_right] = root_left;
        dsu_size[root_left] += dsu_size[root_right];
        adjacent[left][right] = true;
        adjacent[right][left] = true;
    }

    const operation_start = edge_start + 2 * (n - 1);
    for (0..q) |query| {
        const offset = operation_start + 4 * query;
        const kind = packed[offset];
        const first = packed[offset + 1];
        const second = packed[offset + 2];
        const third = packed[offset + 3];
        if (kind == 0) {
            if (first < 0 or first >= nv or second < 1 or second >= MODULUS or third < 0 or third >= MODULUS) return -1;
        } else if (kind == 1) {
            if (first < 0 or first >= nv or second < 0 or second >= nv or third < 0 or third >= MODULUS) return -1;
        } else return -1;
    }

    var parent: [MAX_N]usize = @splat(0);
    var depth: [MAX_N]usize = @splat(0);
    var subtree: [MAX_N]usize = @splat(0);
    var heavy: [MAX_N]usize = @splat(MAX_N);
    var order: [MAX_N]usize = @splat(0);
    var stack: [MAX_N]usize = @splat(0);
    var order_count: usize = 1;
    var top: usize = 1;
    parent[0] = 0;
    subtree[0] = 1;
    stack[0] = 0;
    order[0] = 0;
    while (top > 0) {
        top -= 1;
        const vertex = stack[top];
        for (0..n) |neighbor| {
            if (!adjacent[vertex][neighbor] or neighbor == parent[vertex]) continue;
            parent[neighbor] = vertex;
            depth[neighbor] = depth[vertex] + 1;
            subtree[neighbor] = 1;
            heavy[neighbor] = MAX_N;
            order[order_count] = neighbor;
            order_count += 1;
            stack[top] = neighbor;
            top += 1;
        }
    }
    var reverse_index = order_count;
    while (reverse_index > 1) {
        reverse_index -= 1;
        const vertex = order[reverse_index];
        const p = parent[vertex];
        subtree[p] += subtree[vertex];
        if (heavy[p] == MAX_N or subtree[vertex] > subtree[heavy[p]] or
            (subtree[vertex] == subtree[heavy[p]] and vertex < heavy[p])) heavy[p] = vertex;
    }

    var head: [MAX_N]usize = @splat(0);
    var position: [MAX_N]usize = @splat(0);
    var chain_vertex: [MAX_N]usize = @splat(0);
    var chain_head: [MAX_N]usize = @splat(0);
    var chain_count: usize = 1;
    var timer: usize = 0;
    chain_vertex[0] = 0;
    chain_head[0] = 0;
    while (chain_count > 0) {
        chain_count -= 1;
        var vertex = chain_vertex[chain_count];
        const current_head = chain_head[chain_count];
        while (vertex != MAX_N) {
            head[vertex] = current_head;
            position[vertex] = timer;
            timer += 1;
            for (0..n) |child| {
                if (adjacent[vertex][child] and parent[child] == vertex and child != heavy[vertex]) {
                    chain_vertex[chain_count] = child;
                    chain_head[chain_count] = child;
                    chain_count += 1;
                }
            }
            vertex = heavy[vertex];
        }
    }

    var base: usize = 1;
    while (base < n) base *= 2;
    var tree: [2 * MAX_N]Aggregate = @splat(.{});
    for (0..2 * base) |node| tree[node] = identityAggregate();
    for (0..n) |vertex| updateLeaf(&tree, base, position[vertex], values[vertex]);
    var answers: [MAX_Q]i64 = @splat(0);
    var answer_count: usize = 0;
    for (0..q) |query| {
        const offset = operation_start + 4 * query;
        const kind = packed[offset];
        const first: usize = @intCast(packed[offset + 1]);
        const second = packed[offset + 2];
        const third = packed[offset + 3];
        if (kind == 0) {
            values[first] = .{ .a = second, .b = third };
            updateLeaf(&tree, base, position[first], values[first]);
        } else {
            const combined = pathComposition(&tree, base, &parent, &depth, &head, &position,
                first, @intCast(second));
            answers[answer_count] = @mod(combined.a * third + combined.b, MODULUS);
            answer_count += 1;
        }
    }

    const required = 8 * answer_count;
    if (output == null or capacity < required) return -2;
    for (0..answer_count) |index| storeI64Le(output, 8 * index, answers[index]);
    return @intCast(required);
}
