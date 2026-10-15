/// Check whether a root-to-leaf path has the requested sum.
const MAX_NODES = 63;

fn pathHasSum(input: []const i64, node: usize, sum: i64, target: i64) bool {
    const base = 2 + 3 * node;
    const next_sum = sum + input[base];
    const left = input[base + 1];
    const right = input[base + 2];
    if (left == -1 and right == -1) return next_sum == target;
    return (left != -1 and pathHasSum(input, @intCast(left), next_sum, target)) or
        (right != -1 and pathHasSum(input, @intCast(right), next_sum, target));
}

export fn path_sum(raw_input: [*]const i64, length: usize) i64 {
    if (length < 2) return -1;
    const input = raw_input[0..length];
    if (input[1] < 0 or input[1] > MAX_NODES) return -1;
    const count: usize = @intCast(input[1]);
    if (length != 2 + 3 * count) return -1;
    if (count == 0) return 0;
    for (0..count) |index| {
        const base = 2 + 3 * index;
        if (input[base] < -2147483648 or input[base] > 2147483647) return -1;
        for (1..3) |edge| {
            if (input[base + edge] < -1 or input[base + edge] >= count) return -1;
        }
    }
    var seen: [MAX_NODES]bool = @splat(false);
    var stack: [MAX_NODES]usize = @splat(0);
    var top: usize = 1;
    var visited: usize = 0;
    stack[0] = 0;
    while (top > 0) {
        top -= 1;
        const node = stack[top];
        if (seen[node]) return -1;
        seen[node] = true;
        visited += 1;
        const base = 2 + 3 * node;
        const left = input[base + 1];
        const right = input[base + 2];
        if (left != -1) { stack[top] = @intCast(left); top += 1; }
        if (right != -1) { stack[top] = @intCast(right); top += 1; }
    }
    if (visited != count) return -1;
    return if (pathHasSum(input, 0, 0, input[0])) 1 else 0;
}
