const MAX_NODES: usize = 256;
const MAX_QUERIES: usize = 1024;
const MAX_ARCS: usize = 510;
const MAX_EULER: usize = 2 * MAX_NODES - 1;
const MAX_BLOCKS: usize = 128;
const MAX_LEVELS: usize = 8;
const MAX_MICRO: usize = 4;

fn shallower(a: u16, b: u16, depth: *const [MAX_EULER]u16) u16 {
    const ia: usize = @intCast(a);
    const ib: usize = @intCast(b);
    if (depth[ia] != depth[ib]) return if (depth[ia] < depth[ib]) a else b;
    return if (a < b) a else b;
}

fn rangeMinimum(first: usize, last: usize, euler_count: usize, block_size: usize,
    depth: *const [MAX_EULER]u16, pattern: *const [MAX_BLOCKS]u8,
    micro: *const [8][MAX_MICRO][MAX_MICRO]u8,
    macro_table: *const [MAX_LEVELS][MAX_BLOCKS]u16,
    logs: *const [MAX_BLOCKS + 1]u8) usize {
    const block_a = first / block_size;
    const block_b = last / block_size;
    const offset_a = first % block_size;
    const offset_b = last % block_size;
    const shape_a: usize = @intCast(pattern[block_a]);
    const shape_b: usize = @intCast(pattern[block_b]);
    if (block_a == block_b) return block_a * block_size + @as(usize, @intCast(micro[shape_a][offset_a][offset_b]));
    const base_a = block_a * block_size;
    const base_b = block_b * block_size;
    const len_a = @min(block_size, euler_count - base_a);
    var best = base_a + @as(usize, @intCast(micro[shape_a][offset_a][len_a - 1]));
    const right_best = base_b + @as(usize, @intCast(micro[shape_b][0][offset_b]));
    best = shallower(@intCast(best), @intCast(right_best), depth);
    if (block_b > block_a + 1) {
        const lo = block_a + 1;
        const hi = block_b - 1;
        const count = hi - lo + 1;
        const level: usize = @intCast(logs[count]);
        const span = @as(usize, 1) << @intCast(level);
        best = shallower(@intCast(best), macro_table[level][lo], depth);
        best = shallower(@intCast(best), macro_table[level][hi - span + 1], depth);
    }
    best
}

export fn lowest_common_ancestor_farach_colton_bender(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 4) return -1;
    if (input[0] < 1 or input[0] > MAX_NODES) return -1;
    const n: usize = @intCast(input[0]);
    if (input[1] < 0 or input[1] >= @as(i64, @intCast(n)) or
        input[2] != @as(i64, @intCast(n - 1)) or input[3] < 0 or input[3] > MAX_QUERIES) return -1;
    const edge_count: usize = @intCast(input[2]);
    const query_count: usize = @intCast(input[3]);
    const query_offset = 4 + 2 * edge_count;
    if (length != query_offset + 2 * query_count) return -1;
    const root: usize = @intCast(input[1]);

    var head: [MAX_NODES]i32 = @splat(-1);
    var arc_to: [MAX_ARCS]usize = @splat(0);
    var arc_next: [MAX_ARCS]i32 = @splat(-1);
    var parent: [MAX_NODES]i32 = @splat(-2);
    var tree_depth: [MAX_NODES]usize = @splat(0);
    var first: [MAX_NODES]usize = @splat(0);
    var euler: [MAX_EULER]u16 = @splat(0);
    var euler_depth: [MAX_EULER]u16 = @splat(0);
    var stack_node: [MAX_NODES]usize = @splat(0);
    var stack_arc: [MAX_NODES]i32 = @splat(-1);
    var arcs: usize = 0;
    for (0..edge_count) |edge| {
        const u = input[4 + 2 * edge];
        const v = input[5 + 2 * edge];
        if (u < 0 or u >= @as(i64, @intCast(n)) or v < 0 or v >= @as(i64, @intCast(n)) or u == v) return -1;
        const a: usize = @intCast(u);
        const b: usize = @intCast(v);
        arc_to[arcs] = b; arc_next[arcs] = head[a]; head[a] = @intCast(arcs); arcs += 1;
        arc_to[arcs] = a; arc_next[arcs] = head[b]; head[b] = @intCast(arcs); arcs += 1;
    }
    for (0..query_count) |query| {
        for (0..2) |side| {
            const node = input[query_offset + 2 * query + side];
            if (node < 0 or node >= @as(i64, @intCast(n))) return -1;
        }
    }

    var euler_count: usize = 1;
    var top: usize = 1;
    var reached: usize = 1;
    parent[root] = -1;
    first[root] = 0;
    euler[0] = @intCast(root);
    stack_node[0] = root;
    stack_arc[0] = head[root];
    while (top > 0) {
        const slot = top - 1;
        const node = stack_node[slot];
        const arc = stack_arc[slot];
        if (arc < 0) {
            top -= 1;
            if (top > 0) {
                const up = stack_node[top - 1];
                euler[euler_count] = @intCast(up);
                euler_depth[euler_count] = @intCast(tree_depth[up]);
                euler_count += 1;
            }
            continue;
        }
        const arc_index: usize = @intCast(arc);
        stack_arc[slot] = arc_next[arc_index];
        const neighbor = arc_to[arc_index];
        if (@as(i32, @intCast(neighbor)) == parent[node]) continue;
        if (parent[neighbor] != -2) return -1;
        parent[neighbor] = @intCast(node);
        tree_depth[neighbor] = tree_depth[node] + 1;
        first[neighbor] = euler_count;
        euler[euler_count] = @intCast(neighbor);
        euler_depth[euler_count] = @intCast(tree_depth[neighbor]);
        euler_count += 1;
        reached += 1;
        stack_node[top] = neighbor;
        stack_arc[top] = head[neighbor];
        top += 1;
    }
    if (reached != n) return -1;
    if (output_capacity < query_count or (query_count != 0 and output == null)) return -2;

    var logarithm: usize = 0;
    var value = euler_count;
    while (value > 1) : (value >>= 1) logarithm += 1;
    const block_size = @max(1, logarithm / 2);
    const block_count = (euler_count + block_size - 1) / block_size;
    var micro: [8][MAX_MICRO][MAX_MICRO]u8 = undefined;
    var pattern: [MAX_BLOCKS]u8 = @splat(0);
    var logs: [MAX_BLOCKS + 1]u8 = @splat(0);
    var macro_table: [MAX_LEVELS][MAX_BLOCKS]u16 = @splat(@splat(0));
    for (0..(@as(usize, 1) << @intCast(block_size - 1))) |shape| {
        var relative: [MAX_MICRO]i32 = @splat(0);
        for (0..block_size - 1) |step| {
            relative[step + 1] = relative[step] + (if (((shape >> @intCast(step)) & 1) != 0) 1 else -1);
        }
        for (0..block_size) |left| {
            for (left..block_size) |right| {
                var best = left;
                for (left + 1..right + 1) |at| if (relative[at] < relative[best]) { best = at; };
                micro[shape][left][right] = @intCast(best);
            }
        }
    }
    for (0..block_count) |block| {
        const base = block * block_size;
        const end = @min(euler_count, base + block_size);
        var best = base;
        for (base..end - 1) |at| {
            if (euler_depth[at + 1] > euler_depth[at]) pattern[block] |= @as(u8, 1) << @intCast(at - base);
            best = shallower(@intCast(best), @intCast(at + 1), &euler_depth);
        }
        macro_table[0][block] = @intCast(best);
    }
    for (2..block_count + 1) |count| logs[count] = logs[count / 2] + 1;
    var macro_levels: usize = 1;
    while ((@as(usize, 1) << @intCast(macro_levels)) <= block_count and macro_levels < MAX_LEVELS) {
        const half = @as(usize, 1) << @intCast(macro_levels - 1);
        const span = 2 * half;
        for (0..block_count - span + 1) |block| {
            macro_table[macro_levels][block] = shallower(
                macro_table[macro_levels - 1][block], macro_table[macro_levels - 1][block + half], &euler_depth);
        }
        macro_levels += 1;
    }

    var answers: [MAX_QUERIES]u8 = @splat(0);
    for (0..query_count) |query| {
        const u: usize = @intCast(input[query_offset + 2 * query]);
        const v: usize = @intCast(input[query_offset + 2 * query + 1]);
        const left = @min(first[u], first[v]);
        const right = @max(first[u], first[v]);
        const at = rangeMinimum(left, right, euler_count, block_size, &euler_depth, &pattern, &micro, &macro_table, &logs);
        answers[query] = @intCast(euler[at]);
    }
    for (0..query_count) |query| output[query] = answers[query];
    return @intCast(query_count);
}
