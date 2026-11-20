module fenwick_tree_in_block_array_rectangle_count;

fn void inner_add(long* trees, usz n, usz node, long y, long delta) {
    usz index = (usz)y + 1;
    while (index <= n) {
        trees[node * 25 + index] += delta;
        index += index & (~index + 1);
    }
}

fn long inner_prefix(const long* trees, usz node, long y_limit) {
    long total = 0;
    usz index = (usz)y_limit;
    while (index > 0) {
        total += trees[node * 25 + index];
        index -= index & (~index + 1);
    }
    return total;
}

fn long prefix_count(const long* ys, const long* trees,
                     usz block_size, usz x_limit, long y_limit) {
    usz full_blocks = x_limit / block_size;
    usz node = full_blocks;
    long total = 0;
    while (node > 0) {
        total += inner_prefix(trees, node, y_limit);
        node -= node & (~node + 1);
    }
    for (usz x = full_blocks * block_size; x < x_limit; x++)
        if (ys[x] < y_limit) total++;
    return total;
}

fn long fenwick_tree_in_block_array_rectangle_count(long* input, usz length)
    @export("fenwick_tree_in_block_array_rectangle_count") {
    if (input == null || length < 2 || length > 187) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > 24 || q_value < 1 || q_value > 32) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    usz operations_at = 2 + n;
    if (length != operations_at + 5 * q) return -1;

    long[24] ys = {};
    for (usz x = 0; x < n; x++) {
        ys[x] = input[2 + x];
        if (ys[x] < 0 || ys[x] >= n_value) return -1;
    }
    for (usz j = 0; j < q; j++) {
        usz at = operations_at + 5 * j;
        long kind = input[at];
        if (kind == 0) {
            if (input[at + 1] < 0 || input[at + 1] >= n_value
                    || input[at + 2] < 0 || input[at + 2] >= n_value
                    || input[at + 3] != 0 || input[at + 4] != 0) return -1;
        } else if (kind == 1) {
            if (input[at + 1] < 0 || input[at + 1] > input[at + 2]
                    || input[at + 2] > n_value
                    || input[at + 3] < 0 || input[at + 3] > input[at + 4]
                    || input[at + 4] > n_value) return -1;
        } else return -1;
    }

    usz block_size = 1;
    while (block_size * block_size < n) block_size++;
    usz block_count = (n + block_size - 1) / block_size;
    long[150] trees = {};
    for (usz x = 0; x < n; x++) {
        usz node = x / block_size + 1;
        while (node <= block_count) {
            inner_add(&trees[0], n, node, ys[x], 1);
            node += node & (~node + 1);
        }
    }

    long checksum = 0, query_ordinal = 0;
    for (usz j = 0; j < q; j++) {
        usz at = operations_at + 5 * j;
        if (input[at] == 0) {
            usz x = (usz)input[at + 1];
            long new_y = input[at + 2];
            usz node = x / block_size + 1;
            while (node <= block_count) {
                inner_add(&trees[0], n, node, ys[x], -1);
                inner_add(&trees[0], n, node, new_y, 1);
                node += node & (~node + 1);
            }
            ys[x] = new_y;
        } else {
            usz x_left = (usz)input[at + 1], x_right = (usz)input[at + 2];
            long y_low = input[at + 3], y_high = input[at + 4];
            long count = prefix_count(&ys[0], &trees[0], block_size, x_right, y_high)
                - prefix_count(&ys[0], &trees[0], block_size, x_left, y_high)
                - prefix_count(&ys[0], &trees[0], block_size, x_right, y_low)
                + prefix_count(&ys[0], &trees[0], block_size, x_left, y_low);
            query_ordinal++;
            checksum += query_ordinal * count;
        }
    }
    return checksum;
}
