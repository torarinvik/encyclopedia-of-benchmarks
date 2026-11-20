const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_PARSEABLE_LENGTH: usize = 99;

fn findRoot(parent: *[MAX_N]i64, vertex_input: usize) usize {
    var vertex = vertex_input;
    while (parent[vertex] >= 0) {
        const ancestor: usize = @intCast(parent[vertex]);
        if (parent[ancestor] >= 0) parent[vertex] = parent[ancestor];
        vertex = ancestor;
    }
    return vertex;
}

fn uniteRoots(parent: *[MAX_N]i64, left: *[MAX_N]i64, right: *[MAX_N]i64,
    root_a_input: usize, root_b_input: usize) usize {
    var root_a = root_a_input;
    var root_b = root_b_input;
    if (parent[root_a] > parent[root_b]) { const temporary = root_a; root_a = root_b; root_b = temporary; }
    parent[root_a] += parent[root_b];
    parent[root_b] = @intCast(root_a);
    left[root_a] = @min(left[root_a], left[root_b]);
    right[root_a] = @max(right[root_a], right[root_b]);
    return root_a;
}

export fn range_union_find(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = values.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N)) or input[1] < 0 or
        input[1] > @as(i64, @intCast(MAX_Q)) or length != 2 + 3 * @as(usize, @intCast(input[1]))) return -1;
    const n: usize = @intCast(input[0]);
    const q: usize = @intCast(input[1]);
    for (0..q) |operation| {
        const offset = 2 + 3 * operation;
        const opcode = input[offset];
        const first = input[offset + 1];
        const second = input[offset + 2];
        if (opcode == 0) {
            if (first < 0 or first > second or second > @as(i64, @intCast(n))) return -1;
        } else if (opcode == 1) {
            if (first < 0 or first >= @as(i64, @intCast(n)) or second < 0 or second >= @as(i64, @intCast(n))) return -1;
        } else if (opcode == 2) {
            if (first < 0 or first >= @as(i64, @intCast(n)) or second != 0) return -1;
        } else return -1;
    }

    var parent: [MAX_N]i64 = @splat(-1);
    var left: [MAX_N]i64 = @splat(0);
    var right: [MAX_N]i64 = @splat(0);
    for (0..n) |vertex| { left[vertex] = @intCast(vertex); right[vertex] = @intCast(vertex + 1); }
    var components: i64 = @intCast(n);
    var total: i64 = 0;
    for (0..q) |operation| {
        const offset = 2 + 3 * operation;
        const opcode = input[offset];
        const first: usize = @intCast(input[offset + 1]);
        const second: usize = @intCast(input[offset + 2]);
        var observed: i64 = 0;
        if (opcode == 0) {
            if (first < second) {
                var root = findRoot(&parent, first);
                var next: usize = @intCast(right[root]);
                while (next < second) {
                    const next_root = findRoot(&parent, next);
                    if (root == next_root) break;
                    root = uniteRoots(&parent, &left, &right, root, next_root);
                    components -= 1;
                    next = @intCast(right[root]);
                }
            }
            observed = components;
        } else if (opcode == 1) {
            if (findRoot(&parent, first) == findRoot(&parent, second)) {
                observed = 1;
            } else {
                observed = 0;
            }
        } else {
            observed = -parent[findRoot(&parent, first)];
        }
        total += @as(i64, @intCast(operation + 1)) * observed;
    }
    return total;
}
