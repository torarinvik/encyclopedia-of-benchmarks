const MAX_TREE_NODES: usize = 15;
const MAX_TOTAL_NODES: usize = 30;
const MAX_PARSEABLE_LENGTH: usize = 93;

fn validTree(input: [*c]const i64, offset: usize, node_count: usize) bool {
    var visited: [MAX_TREE_NODES]bool = @splat(false);
    var parents: [MAX_TREE_NODES]usize = @splat(0);
    var stack: [MAX_TREE_NODES]usize = @splat(0);
    var top: usize = 1;
    var reached: usize = 0;
    while (top > 0) {
        top -= 1;
        const node = stack[top];
        if (node >= node_count or visited[node]) return false;
        visited[node] = true;
        reached += 1;
        const base = offset + 3 * node;
        const left = input[base + 1];
        const right = input[base + 2];
        if (left == -1 and right == -1) continue;
        if (left < 0 or right < 0 or left >= @as(i64, @intCast(node_count)) or
            right >= @as(i64, @intCast(node_count)) or left == right or left == 0 or right == 0) return false;
        const left_index: usize = @intCast(left);
        const right_index: usize = @intCast(right);
        parents[left_index] += 1;
        parents[right_index] += 1;
        if (parents[left_index] != 1 or parents[right_index] != 1) return false;
        stack[top] = right_index;
        top += 1;
        stack[top] = left_index;
        top += 1;
    }
    if (reached != node_count or parents[0] != 0) return false;
    for (1..node_count) |node| {
        if (parents[node] != 1) return false;
    }
    return true;
}

export fn same_fringe_leaf_iterator(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE_LENGTH) return -1;
    const n_a_word = input[0];
    const n_b_word = input[1];
    if (n_a_word < 1 or n_a_word > @as(i64, @intCast(MAX_TREE_NODES)) or
        n_b_word < 1 or n_b_word > @as(i64, @intCast(MAX_TREE_NODES))) return -1;
    const n_a: usize = @intCast(n_a_word);
    const n_b: usize = @intCast(n_b_word);
    if (n_a + n_b > MAX_TOTAL_NODES or length != 2 + 3 * (n_a + n_b)) return -1;
    const offset_a: usize = 2;
    const offset_b: usize = 2 + 3 * n_a;
    if (!validTree(input, offset_a, n_a) or !validTree(input, offset_b, n_b)) return -1;

    var stack_a: [MAX_TREE_NODES]usize = @splat(0);
    var stack_b: [MAX_TREE_NODES]usize = @splat(0);
    var top_a: usize = 1;
    var top_b: usize = 1;
    while (true) {
        var have_a = false;
        var have_b = false;
        var leaf_a: i64 = 0;
        var leaf_b: i64 = 0;
        while (top_a > 0 and !have_a) {
            top_a -= 1;
            const node = stack_a[top_a];
            const base = offset_a + 3 * node;
            const left = input[base + 1];
            const right = input[base + 2];
            if (left == -1) {
                leaf_a = input[base];
                have_a = true;
            } else {
                stack_a[top_a] = @intCast(right);
                top_a += 1;
                stack_a[top_a] = @intCast(left);
                top_a += 1;
            }
        }
        while (top_b > 0 and !have_b) {
            top_b -= 1;
            const node = stack_b[top_b];
            const base = offset_b + 3 * node;
            const left = input[base + 1];
            const right = input[base + 2];
            if (left == -1) {
                leaf_b = input[base];
                have_b = true;
            } else {
                stack_b[top_b] = @intCast(right);
                top_b += 1;
                stack_b[top_b] = @intCast(left);
                top_b += 1;
            }
        }
        if (!have_a or !have_b) {
            if (have_a == have_b) return 1;
            return 0;
        }
        if (leaf_a != leaf_b) return 0;
    }
    return -1;
}
