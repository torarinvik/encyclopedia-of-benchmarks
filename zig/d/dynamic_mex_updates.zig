const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_OUTPUT_BYTES: usize = 8 * MAX_Q;

fn treeSet(tree: *[128]i32, base: usize, value: usize, present: i32) void {
    var node = base + value;
    tree[node] = present;
    node /= 2;
    while (node > 0) {
        tree[node] = tree[2 * node] + tree[2 * node + 1];
        node /= 2;
    }
}

fn findMex(tree: *const [128]i32, base: usize, domain_size: usize) usize {
    var node: usize = 1;
    var start: usize = 0;
    var span = base;
    while (span > 1) {
        const half = span / 2;
        const left_width = if (start >= domain_size) 0 else @min(half, domain_size - start);
        if (@as(usize, @intCast(tree[2 * node])) < left_width) {
            node *= 2;
            span = half;
        } else {
            node = 2 * node + 1;
            start += half;
            span = half;
        }
    }
    return start;
}

fn writeI64(output: *[MAX_OUTPUT_BYTES]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn dynamic_mex_updates(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 99) return -1;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or
        q_value < 0 or q_value > @as(i64, @intCast(MAX_Q))) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 2 + n + 2 * q) return -1;

    var current: [MAX_N]i64 = @splat(0);
    var update_indices: [MAX_Q]usize = @splat(0);
    var update_values: [MAX_Q]i64 = @splat(0);
    for (0..n) |index| {
        const value = input[2 + index];
        if (value < -1000 or value > 1000) return -1;
        current[index] = value;
    }
    var cursor = 2 + n;
    for (0..q) |operation| {
        const index = input[cursor];
        const value = input[cursor + 1];
        cursor += 2;
        if (index < 0 or index >= n_value or value < -1000 or value > 1000) return -1;
        update_indices[operation] = @intCast(index);
        update_values[operation] = value;
    }
    const needed = 8 * q;
    if (needed > 0 and (output == null or capacity < needed)) return -2;

    var base: usize = 1;
    while (base < n + 1) base *= 2;
    var frequencies: [MAX_N + 1]i32 = @splat(0);
    var tree: [128]i32 = @splat(0);
    for (0..n) |index| {
        const value = current[index];
        if (value >= 0 and value <= n_value) frequencies[@intCast(value)] += 1;
    }
    for (0..n + 1) |value| {
        if (frequencies[value] > 0) tree[base + value] = 1;
    }
    var node = base - 1;
    while (node > 0) : (node -= 1) {
        tree[node] = tree[2 * node] + tree[2 * node + 1];
    }

    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    for (0..q) |operation| {
        const index = update_indices[operation];
        const old_value = current[index];
        const new_value = update_values[operation];
        if (old_value != new_value) {
            if (old_value >= 0 and old_value <= n_value) {
                const old_index: usize = @intCast(old_value);
                frequencies[old_index] -= 1;
                if (frequencies[old_index] == 0) treeSet(&tree, base, old_index, 0);
            }
            if (new_value >= 0 and new_value <= n_value) {
                const new_index: usize = @intCast(new_value);
                if (frequencies[new_index] == 0) treeSet(&tree, base, new_index, 1);
                frequencies[new_index] += 1;
            }
            current[index] = new_value;
        }
        writeI64(&staged, 8 * operation, @intCast(findMex(&tree, base, n + 1)));
    }
    for (0..needed) |byte| output[byte] = staged[byte];
    return @intCast(needed);
}
