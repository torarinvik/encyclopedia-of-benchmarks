const MAX_N: usize = 64;
const MAX_PARSEABLE_LENGTH: usize = 65;

fn buildInterval(
    lo: usize,
    hi: usize,
    path: []const usize,
    prefix: []const usize,
    gbst_parent: []i64,
    left_child: []i64,
    right_child: []i64,
    local_size: []i64,
) usize {
    const total_weight = prefix[hi] - prefix[lo];
    var low = lo;
    var high = hi;
    while (high - low > 1) {
        const middle = (low + high) / 2;
        if (2 * (prefix[middle] - prefix[lo]) <= total_weight) {
            low = middle;
        } else {
            high = middle;
        }
    }
    const pivot = low;
    const node = path[pivot];
    local_size[node] = @intCast(hi - lo);
    if (lo < pivot) {
        const child = buildInterval(lo, pivot, path, prefix, gbst_parent,
            left_child, right_child, local_size);
        left_child[node] = @intCast(child);
        gbst_parent[child] = @intCast(node);
    }
    if (pivot + 1 < hi) {
        const child = buildInterval(pivot + 1, hi, path, prefix, gbst_parent,
            left_child, right_child, local_size);
        right_child[node] = @intCast(child);
        gbst_parent[child] = @intCast(node);
    }
    return node;
}

export fn global_balanced_binary_tree(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N))) return -1;
    if (length != @as(usize, @intCast(n_value))) return -1;
    const n: usize = @intCast(n_value);

    var parent = [_]i64{-1} ** MAX_N;
    var subtree_size = [_]usize{1} ** MAX_N;
    var heavy_child = [_]i64{-1} ** MAX_N;
    var gbst_parent = [_]i64{-1} ** MAX_N;
    var left_child = [_]i64{-1} ** MAX_N;
    var right_child = [_]i64{-1} ** MAX_N;
    var local_size = [_]i64{0} ** MAX_N;
    var path = [_]usize{0} ** MAX_N;
    var prefix = [_]usize{0} ** (MAX_N + 1);

    for (1..n) |vertex| {
        const p = input[vertex];
        if (p < 0 or p >= @as(i64, @intCast(vertex))) return -1;
        parent[vertex] = p;
    }
    var cursor = n;
    while (cursor > 1) {
        cursor -= 1;
        const p: usize = @intCast(parent[cursor]);
        subtree_size[p] += subtree_size[cursor];
    }
    for (1..n) |vertex| {
        const p: usize = @intCast(parent[vertex]);
        const current = heavy_child[p];
        if (current < 0 or subtree_size[vertex] > subtree_size[@intCast(current)]) {
            heavy_child[p] = @intCast(vertex);
        }
    }

    for (0..n) |head| {
        if (head > 0 and heavy_child[@intCast(parent[head])] == @as(i64, @intCast(head))) continue;
        var path_length: usize = 0;
        var vertex = @as(i64, @intCast(head));
        prefix[0] = 0;
        while (vertex >= 0) {
            const node: usize = @intCast(vertex);
            const child = heavy_child[node];
            const weight = subtree_size[node] -
                (if (child >= 0) subtree_size[@intCast(child)] else 0);
            path[path_length] = node;
            prefix[path_length + 1] = prefix[path_length] + weight;
            path_length += 1;
            vertex = child;
        }
        const root = buildInterval(0, path_length, path[0..], prefix[0..],
            gbst_parent[0..], left_child[0..], right_child[0..], local_size[0..]);
        gbst_parent[root] = if (head == 0) -1 else parent[head];
    }

    var checksum: i64 = 0;
    for (0..n) |vertex| {
        const record = (gbst_parent[vertex] + 1)
            + 65 * (left_child[vertex] + 1)
            + 4225 * (right_child[vertex] + 1)
            + 274625 * local_size[vertex];
        checksum += @as(i64, @intCast(vertex + 1)) * record;
    }
    return checksum;
}
