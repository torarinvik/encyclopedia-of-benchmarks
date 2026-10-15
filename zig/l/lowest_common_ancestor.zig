const MAX_NODE_COUNT: usize = 1023;
const INVALID_RESULT: i64 = -1;

export fn lowest_common_ancestor(input: [*]const i64, length: usize) i64 {
    if (length < 4 or input[0] < 2 or input[0] > 1023) return INVALID_RESULT;
    const count: usize = @intCast(input[0]);
    if (length != 4 + 3 * count) return INVALID_RESULT;
    for (1..4) |field| {
        if (input[field] < 0 or input[field] >= @as(i64, @intCast(count))) return INVALID_RESULT;
    }
    if (input[2] == input[3]) return INVALID_RESULT;
    const root: usize = @intCast(input[1]);
    const p: usize = @intCast(input[2]);
    const q: usize = @intCast(input[3]);

    var parent: [MAX_NODE_COUNT]i64 = @splat(-1);
    var stack: [MAX_NODE_COUNT]usize = @splat(0);
    var path_p: [MAX_NODE_COUNT]usize = @splat(0);
    var path_q: [MAX_NODE_COUNT]usize = @splat(0);
    var seen: [MAX_NODE_COUNT]bool = @splat(false);
    for (0..count) |node| {
        const offset = 4 + 3 * node;
        if (input[offset] < -1_000_000_000 or input[offset] > 1_000_000_000) return INVALID_RESULT;
        for (1..3) |edge| {
            const child = input[offset + edge];
            if (child < -1 or child >= @as(i64, @intCast(count))) return INVALID_RESULT;
            if (child >= 0) {
                const child_index: usize = @intCast(child);
                if (parent[child_index] != -1) return INVALID_RESULT;
                parent[child_index] = @intCast(node);
            }
        }
    }
    if (parent[root] != -1) return INVALID_RESULT;
    for (0..count) |node| {
        if (node != root and parent[node] == -1) return INVALID_RESULT;
    }

    var top: usize = 0;
    var reached: usize = 0;
    stack[top] = root;
    top += 1;
    while (top > 0) {
        top -= 1;
        const node = stack[top];
        if (seen[node]) return INVALID_RESULT;
        seen[node] = true;
        reached += 1;
        const offset = 4 + 3 * node;
        for (1..3) |edge| {
            const child = input[offset + edge];
            if (child >= 0) {
                stack[top] = @intCast(child);
                top += 1;
            }
        }
    }
    if (reached != count) return INVALID_RESULT;

    var depth_p: usize = 0;
    var depth_q: usize = 0;
    var current = p;
    path_p[depth_p] = current;
    depth_p += 1;
    while (current != root) {
        current = @intCast(parent[current]);
        path_p[depth_p] = current;
        depth_p += 1;
    }
    current = q;
    path_q[depth_q] = current;
    depth_q += 1;
    while (current != root) {
        current = @intCast(parent[current]);
        path_q[depth_q] = current;
        depth_q += 1;
    }
    var ancestor: i64 = INVALID_RESULT;
    while (depth_p > 0 and depth_q > 0 and path_p[depth_p - 1] == path_q[depth_q - 1]) {
        ancestor = @intCast(path_p[depth_p - 1]);
        depth_p -= 1;
        depth_q -= 1;
    }
    return ancestor;
}
