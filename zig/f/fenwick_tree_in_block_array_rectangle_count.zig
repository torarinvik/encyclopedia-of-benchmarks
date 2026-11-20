/// Online rectangle counts using Fenwick trees over x-blocks and y-values.
fn innerAdd(trees: []i64, n: usize, node: usize, y: i64, delta: i64) void {
    var index: usize = @intCast(y);
    index += 1;
    while (index <= n) {
        trees[node * 25 + index] += delta;
        index += index & (~index +% 1);
    }
}

fn innerPrefix(trees: []const i64, node: usize, y_limit: i64) i64 {
    var index: usize = @intCast(y_limit);
    var total: i64 = 0;
    while (index > 0) {
        total += trees[node * 25 + index];
        index &= index - 1;
    }
    return total;
}

fn prefixCount(ys: []const i64, trees: []const i64, block_size: usize,
               x_limit: usize, y_limit: i64) i64 {
    const full_blocks = x_limit / block_size;
    var node = full_blocks;
    var total: i64 = 0;
    while (node > 0) {
        total += innerPrefix(trees, node, y_limit);
        node &= node - 1;
    }
    var x = full_blocks * block_size;
    while (x < x_limit) : (x += 1) {
        if (ys[x] < y_limit) total += 1;
    }
    return total;
}

export fn fenwick_tree_in_block_array_rectangle_count(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 187) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > 24 or q_value < 1 or q_value > 32) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    const operations_at = 2 + n;
    if (length != operations_at + 5 * q) return -1;

    var ys: [24]i64 = undefined;
    for (0..n) |x| {
        ys[x] = input[2 + x];
        if (ys[x] < 0 or ys[x] >= n_value) return -1;
    }
    for (0..q) |j| {
        const at = operations_at + 5 * j;
        if (input[at] == 0) {
            if (input[at + 1] < 0 or input[at + 1] >= n_value
                or input[at + 2] < 0 or input[at + 2] >= n_value
                or input[at + 3] != 0 or input[at + 4] != 0) return -1;
        } else if (input[at] == 1) {
            if (input[at + 1] < 0 or input[at + 1] > input[at + 2]
                or input[at + 2] > n_value
                or input[at + 3] < 0 or input[at + 3] > input[at + 4]
                or input[at + 4] > n_value) return -1;
        } else return -1;
    }

    var block_size: usize = 1;
    while (block_size * block_size < n) : (block_size += 1) {}
    const block_count = (n + block_size - 1) / block_size;
    var trees = [_]i64{0} ** 150;
    for (0..n) |x| {
        var node = x / block_size + 1;
        while (node <= block_count) {
            innerAdd(trees[0..], n, node, ys[x], 1);
            node += node & (~node +% 1);
        }
    }

    var checksum: i64 = 0;
    var query_ordinal: i64 = 0;
    for (0..q) |j| {
        const at = operations_at + 5 * j;
        if (input[at] == 0) {
            const x: usize = @intCast(input[at + 1]);
            const new_y = input[at + 2];
            var node = x / block_size + 1;
            while (node <= block_count) {
                innerAdd(trees[0..], n, node, ys[x], -1);
                innerAdd(trees[0..], n, node, new_y, 1);
                node += node & (~node +% 1);
            }
            ys[x] = new_y;
        } else {
            const x_left: usize = @intCast(input[at + 1]);
            const x_right: usize = @intCast(input[at + 2]);
            const y_low = input[at + 3];
            const y_high = input[at + 4];
            const count = prefixCount(ys[0..], trees[0..], block_size, x_right, y_high)
                - prefixCount(ys[0..], trees[0..], block_size, x_left, y_high)
                - prefixCount(ys[0..], trees[0..], block_size, x_right, y_low)
                + prefixCount(ys[0..], trees[0..], block_size, x_left, y_low);
            query_ordinal += 1;
            checksum += query_ordinal * count;
        }
    }
    return checksum;
}
