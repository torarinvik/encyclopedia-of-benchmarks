const MAX_TEXT: usize = 8;
const MAX_INPUT: usize = 10;
const MAX_SUFFIXES: usize = 9;
const MAX_NODES: usize = 17;
const MAX_OUTPUT_WORDS: usize = 86;

const TreeRecord = struct { parent_rep: i64, parent_depth: i64, node_rep: i64, node_depth: i64, leaf_start: i64 };

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn symbol_at(input: [*]const i64, n: usize, position: usize) usize {
    return if (position == n) 0 else @intCast(input[position + 1]);
}

fn suffix_less(input: [*]const i64, n: usize, left_start: usize, right_start: usize) bool {
    var left = left_start;
    var right = right_start;
    const total = n + 1;
    while (left < total and right < total) {
        const a = symbol_at(input, n, left);
        const b = symbol_at(input, n, right);
        if (a != b) return a < b;
        left += 1;
        right += 1;
    }
    return left == total and right != total;
}

fn record_less(left: TreeRecord, right: TreeRecord) bool {
    if (left.node_depth != right.node_depth) return left.node_depth < right.node_depth;
    if (left.node_rep != right.node_rep) return left.node_rep < right.node_rep;
    return left.leaf_start < right.leaf_start;
}

export fn suffix_tree_from_sa_lcp(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_raw = input[0];
    if (n_raw < 0 or n_raw > @as(i64, MAX_TEXT) or length != @as(usize, @intCast(n_raw)) + 1) return -1;
    const n: usize = @intCast(n_raw);
    for (0..n) |index| if (input[index + 1] < 1 or input[index + 1] > 255) return -1;

    const suffix_count = n + 1;
    var suffix_array: [MAX_SUFFIXES]usize = @splat(0);
    var lcp: [MAX_SUFFIXES]usize = @splat(0);
    for (0..suffix_count) |index| suffix_array[index] = index;
    for (1..suffix_count) |index| {
        const value = suffix_array[index];
        var j = index;
        while (j > 0 and suffix_less(input, n, value, suffix_array[j - 1])) : (j -= 1) {
            suffix_array[j] = suffix_array[j - 1];
        }
        suffix_array[j] = value;
    }
    for (1..suffix_count) |rank| {
        const left = suffix_array[rank - 1];
        const right = suffix_array[rank];
        var common: usize = 0;
        while (left + common < suffix_count and right + common < suffix_count and
            symbol_at(input, n, left + common) == symbol_at(input, n, right + common)) : (common += 1) {}
        lcp[rank] = common;
    }

    var parent: [MAX_NODES]i32 = @splat(0);
    var depth: [MAX_NODES]i32 = @splat(0);
    var representative: [MAX_NODES]i32 = @splat(0);
    var leaf: [MAX_NODES]i32 = @splat(-1);
    var last_child: [MAX_NODES]i32 = @splat(-1);
    var stack: [MAX_NODES]usize = @splat(0);
    var node_count: usize = 1;
    var stack_size: usize = 1;
    parent[0] = -1;
    representative[0] = -1;
    stack[0] = 0;
    for (0..suffix_count) |rank| {
        if (rank > 0) {
            const common: i32 = @intCast(lcp[rank]);
            while (stack_size > 1 and depth[stack[stack_size - 1]] > common) stack_size -= 1;
            const top = stack[stack_size - 1];
            if (depth[top] < common) {
                const old_child = last_child[top];
                if (old_child < 0) return -1;
                const old: usize = @intCast(old_child);
                const internal = node_count;
                node_count += 1;
                parent[internal] = @intCast(top);
                depth[internal] = common;
                representative[internal] = representative[old];
                leaf[internal] = -1;
                last_child[internal] = old_child;
                parent[old] = @intCast(internal);
                last_child[top] = @intCast(internal);
                stack[stack_size] = internal;
                stack_size += 1;
            }
        }
        const owner = stack[stack_size - 1];
        const suffix_start = suffix_array[rank];
        const new_leaf = node_count;
        node_count += 1;
        parent[new_leaf] = @intCast(owner);
        depth[new_leaf] = @intCast(suffix_count - suffix_start);
        representative[new_leaf] = @intCast(suffix_start);
        leaf[new_leaf] = @intCast(suffix_start);
        last_child[new_leaf] = -1;
        last_child[owner] = @intCast(new_leaf);
    }

    var records: [MAX_NODES]TreeRecord = @splat(.{ .parent_rep = 0, .parent_depth = 0, .node_rep = 0, .node_depth = 0, .leaf_start = 0 });
    for (0..node_count) |node| {
        if (node == 0) {
            records[node] = .{ .parent_rep = -1, .parent_depth = -1, .node_rep = -1, .node_depth = 0, .leaf_start = -1 };
        } else {
            const p: usize = @intCast(parent[node]);
            records[node] = .{ .parent_rep = representative[p], .parent_depth = depth[p],
                .node_rep = representative[node], .node_depth = depth[node], .leaf_start = leaf[node] };
        }
    }
    for (1..node_count) |index| {
        const value = records[index];
        var j = index;
        while (j > 0 and record_less(value, records[j - 1])) : (j -= 1) records[j] = records[j - 1];
        records[j] = value;
    }

    var staged: [MAX_OUTPUT_WORDS]i64 = @splat(0);
    staged[0] = @intCast(node_count);
    var words: usize = 1;
    for (0..node_count) |node| {
        const record = records[node];
        staged[words] = record.parent_rep; words += 1;
        staged[words] = record.parent_depth; words += 1;
        staged[words] = record.node_rep; words += 1;
        staged[words] = record.node_depth; words += 1;
        staged[words] = record.leaf_start; words += 1;
    }
    const output_bytes = words * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..words) |word| store_i64_le(output, word * 8, staged[word]);
    return @intCast(output_bytes);
}
