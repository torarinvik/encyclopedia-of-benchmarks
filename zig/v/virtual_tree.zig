const MAX_N: usize = 32;
const MAX_K: usize = 32;
const MAX_INPUT: usize = 66;
const MAX_VIRTUAL: usize = 32;
const MAX_CANDIDATES: usize = 64;
const MAX_WORDS: usize = 1 + 3 * MAX_VIRTUAL;

fn lca(a0: usize, b0: usize, parent: *const [MAX_N]usize,
    depth: *const [MAX_N]usize) usize {
    var a = a0;
    var b = b0;
    while (depth[a] > depth[b]) a = parent[a];
    while (depth[b] > depth[a]) b = parent[b];
    while (a != b) { a = parent[a]; b = parent[b]; }
    return a;
}

fn isAncestor(a: usize, b: usize, tin: *const [MAX_N]usize,
    tout: *const [MAX_N]usize) bool {
    return tin[a] <= tin[b] and tin[b] < tout[a];
}

fn sortByTin(items: *[MAX_CANDIDATES]usize, count: usize,
    tin: *const [MAX_N]usize) void {
    for (1..count) |i| {
        const value = items[i];
        var j = i;
        while (j > 0 and tin[items[j - 1]] > tin[value]) {
            items[j] = items[j - 1];
            j -= 1;
        }
        items[j] = value;
    }
}

fn putWord(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn virtual_tree(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const packed = input[0..length];
    const n_value = packed[0];
    const k_value = packed[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or k_value < 0 or
        k_value > @as(i64, @intCast(MAX_K)) or k_value > n_value) return -1;
    const n: usize = @intCast(n_value);
    const k: usize = @intCast(k_value);
    if (length != n + k + 1) return -1;

    var parent: [MAX_N]usize = @splat(0);
    var depth: [MAX_N]usize = @splat(0);
    var children: [MAX_N][MAX_N]usize = @splat(@splat(0));
    var child_count: [MAX_N]usize = @splat(0);
    for (1..n) |vertex| {
        const p_value = packed[vertex + 1];
        if (p_value < 0 or p_value >= n_value or p_value == @as(i64, @intCast(vertex))) return -1;
        const p: usize = @intCast(p_value);
        parent[vertex] = p;
        children[p][child_count[p]] = vertex;
        child_count[p] += 1;
    }
    var marks: [MAX_K]usize = @splat(0);
    for (0..k) |index| {
        const mark_value = packed[n + 1 + index];
        if (mark_value < 0 or mark_value >= n_value) return -1;
        marks[index] = @intCast(mark_value);
        for (0..index) |previous| if (marks[previous] == marks[index]) return -1;
    }

    var tin: [MAX_N]usize = @splat(MAX_N);
    var tout: [MAX_N]usize = @splat(MAX_N);
    var node_stack: [MAX_N]usize = @splat(0);
    var next_stack: [MAX_N]usize = @splat(0);
    var timer: usize = 0;
    var top: usize = 1;
    var reached: usize = 1;
    node_stack[0] = 0;
    tin[0] = timer;
    timer += 1;
    while (top > 0) {
        const frame = top - 1;
        const current = node_stack[frame];
        if (next_stack[frame] == child_count[current]) {
            tout[current] = timer;
            top -= 1;
            continue;
        }
        const child = children[current][next_stack[frame]];
        next_stack[frame] += 1;
        if (tin[child] != MAX_N) return -1;
        tin[child] = timer;
        timer += 1;
        depth[child] = depth[current] + 1;
        reached += 1;
        node_stack[top] = child;
        next_stack[top] = 0;
        top += 1;
    }
    if (reached != n) return -1;

    var words: [MAX_WORDS]i64 = @splat(0);
    var word_count: usize = 1;
    if (k == 0) {
        words[0] = 0;
    } else {
        for (1..k) |i| {
            const value = marks[i];
            var j = i;
            while (j > 0 and tin[marks[j - 1]] > tin[value]) {
                marks[j] = marks[j - 1];
                j -= 1;
            }
            marks[j] = value;
        }
        var nodes: [MAX_CANDIDATES]usize = @splat(0);
        var count: usize = 0;
        nodes[count] = 0;
        count += 1;
        for (0..k) |index| { nodes[count] = marks[index]; count += 1; }
        for (1..k) |index| {
            nodes[count] = lca(marks[index - 1], marks[index], &parent, &depth);
            count += 1;
        }
        sortByTin(&nodes, count, &tin);
        var unique: [MAX_VIRTUAL]usize = @splat(0);
        var unique_count: usize = 0;
        for (0..count) |index| {
            if (unique_count == 0 or unique[unique_count - 1] != nodes[index]) {
                unique[unique_count] = nodes[index];
                unique_count += 1;
            }
        }
        words[0] = @intCast(unique_count);
        var stack: [MAX_VIRTUAL]usize = @splat(0);
        var stack_size: usize = 0;
        for (0..unique_count) |index| {
            const vertex = unique[index];
            while (stack_size > 0 and !isAncestor(stack[stack_size - 1], vertex, &tin, &tout)) {
                stack_size -= 1;
            }
            const virtual_parent = if (stack_size == 0) vertex else stack[stack_size - 1];
            words[word_count] = @intCast(vertex);
            words[word_count + 1] = @intCast(virtual_parent);
            words[word_count + 2] = @intCast(depth[vertex] - depth[virtual_parent]);
            word_count += 3;
            stack[stack_size] = vertex;
            stack_size += 1;
        }
    }

    const output_bytes = word_count * 8;
    if (output == null or capacity < output_bytes) return -2;
    for (0..word_count) |index| putWord(output, index * 8, words[index]);
    return @intCast(output_bytes);
}
