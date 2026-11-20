/// Dynamic range k-th via a Fenwick tree of mutable weighted value trees.
const MAX_N: usize = 12;
const MAX_Q: usize = 16;
const VALUE_COUNT: usize = 61;
const NODE_CAPACITY: usize = 1280;

const Pool = struct {
    left: [NODE_CAPACITY + 1]usize,
    right: [NODE_CAPACITY + 1]usize,
    count: [NODE_CAPACITY + 1]i32,
    roots: [MAX_N + 1]usize,
    current: [MAX_N]i64,
    used: usize,
};

fn change(pool: *Pool, root_arg: usize, low: usize, high: usize,
          coordinate: usize, delta: i32) usize {
    var root = root_arg;
    if (root == 0) {
        pool.used += 1;
        root = pool.used;
    }
    pool.count[root] += delta;
    if (high - low > 1) {
        const middle = (low + high) / 2;
        if (coordinate < middle) {
            pool.left[root] = change(pool, pool.left[root], low, middle, coordinate, delta);
        } else {
            pool.right[root] = change(pool, pool.right[root], middle, high, coordinate, delta);
        }
    }
    return root;
}

fn apply(pool: *Pool, n: usize, position: usize, value: i64, delta: i32) void {
    var node = position + 1;
    while (node <= n) {
        pool.roots[node] = change(pool, pool.roots[node], 0, VALUE_COUNT,
                                  @intCast(value + 30), delta);
        node += node & (~node +% 1);
    }
}

export fn fenwick_weighted_segment_tree_range_kth(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > 79) return -9223372036854775807 - 1;
    const input = input_opt.?;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q)
        return -9223372036854775807 - 1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 2 + n + 4 * q) return -9223372036854775807 - 1;

    var pool: Pool = .{
        .left = @splat(0), .right = @splat(0), .count = @splat(0),
        .roots = @splat(0), .current = @splat(0), .used = 0,
    };
    for (0..n) |position| {
        const value = input[2 + position];
        if (value < -30 or value > 30) return -9223372036854775807 - 1;
        pool.current[position] = value;
        apply(&pool, n, position, value, 1);
    }

    var checksum: i64 = 0;
    var query_number: i64 = 0;
    var cursor: usize = 2 + n;
    for (0..q) |_| {
        const opcode = input[cursor];
        const first = input[cursor + 1];
        const second = input[cursor + 2];
        const third = input[cursor + 3];
        cursor += 4;
        if (opcode == 0) {
            if (first < 0 or first >= n_value or second < -30 or second > 30 or third != 0)
                return -9223372036854775807 - 1;
            const position: usize = @intCast(first);
            apply(&pool, n, position, pool.current[position], -1);
            pool.current[position] = second;
            apply(&pool, n, position, pool.current[position], 1);
        } else if (opcode == 1) {
            if (first < 0 or first >= second or second > n_value or third < 1 or third > second - first)
                return -9223372036854775807 - 1;
            var left_roots: [MAX_N + 1]usize = @splat(0);
            var right_roots: [MAX_N + 1]usize = @splat(0);
            var left_size: usize = 0;
            var right_size: usize = 0;
            var node: usize = @intCast(first);
            while (node > 0) {
                left_roots[left_size] = pool.roots[node];
                left_size += 1;
                node &= node - 1;
            }
            node = @intCast(second);
            while (node > 0) {
                right_roots[right_size] = pool.roots[node];
                right_size += 1;
                node &= node - 1;
            }
            var low: usize = 0;
            var high: usize = VALUE_COUNT;
            var rank: i32 = @intCast(third);
            while (high - low > 1) {
                const middle = (low + high) / 2;
                var left_count: i32 = 0;
                for (0..right_size) |i| left_count += pool.count[pool.left[right_roots[i]]];
                for (0..left_size) |i| left_count -= pool.count[pool.left[left_roots[i]]];
                if (rank <= left_count) {
                    for (0..right_size) |i| right_roots[i] = pool.left[right_roots[i]];
                    for (0..left_size) |i| left_roots[i] = pool.left[left_roots[i]];
                    high = middle;
                } else {
                    rank -= left_count;
                    for (0..right_size) |i| right_roots[i] = pool.right[right_roots[i]];
                    for (0..left_size) |i| left_roots[i] = pool.right[left_roots[i]];
                    low = middle;
                }
            }
            query_number += 1;
            checksum += query_number * @as(i64, @intCast(low)) - query_number * 30;
        } else {
            return -9223372036854775807 - 1;
        }
    }
    return checksum;
}
