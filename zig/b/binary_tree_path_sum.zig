const MAX_NODES: usize = 63;

fn countFrom(input: [*]const i64, node: usize, sum: i64, target: i64) i64 {
    const base = 2 + 3 * node;
    var count: i64 = if (sum == target) 1 else 0;
    const left = input[base + 1];
    const right = input[base + 2];
    if (left >= 0) {
        const child: usize = @intCast(left);
        count += countFrom(input, child, sum + input[2 + 3 * child], target);
    }
    if (right >= 0) {
        const child: usize = @intCast(right);
        count += countFrom(input, child, sum + input[2 + 3 * child], target);
    }
    return count;
}

fn startAtEachNode(input: [*]const i64, node: usize) i64 {
    const base = 2 + 3 * node;
    var count = countFrom(input, node, input[base], input[0]);
    const left = input[base + 1];
    const right = input[base + 2];
    if (left >= 0) count += startAtEachNode(input, @intCast(left));
    if (right >= 0) count += startAtEachNode(input, @intCast(right));
    return count;
}

export fn binary_tree_path_sum(input: [*]const i64, length: usize) i64 {
    if (length < 2 or input[1] < 0 or input[1] > MAX_NODES) return -1;
    const count: usize = @intCast(input[1]);
    if (length != 2 + 3 * count) return -1;
    if (count == 0) return 0;
    var parents = [_]usize{0} ** MAX_NODES;
    for (0..count) |node| {
        const base = 2 + 3 * node;
        if (input[base] < -2147483648 or input[base] > 2147483647) return -1;
        for (1..3) |side| {
            const child = input[base + side];
            if (child < -1 or child >= count) return -1;
            if (child >= 0) {
                const index: usize = @intCast(child);
                parents[index] += 1;
                if (parents[index] > 1) return -1;
            }
        }
    }
    if (parents[0] != 0) return -1;
    for (1..count) |node| if (parents[node] != 1) return -1;
    var seen = [_]bool{false} ** MAX_NODES;
    var stack: [MAX_NODES]usize = undefined;
    var top: usize = 1;
    var reached: usize = 0;
    stack[0] = 0;
    while (top > 0) {
        top -= 1;
        const node = stack[top];
        if (seen[node]) return -1;
        seen[node] = true;
        reached += 1;
        const base = 2 + 3 * node;
        if (input[base + 1] >= 0) { stack[top] = @intCast(input[base + 1]); top += 1; }
        if (input[base + 2] >= 0) { stack[top] = @intCast(input[base + 2]); top += 1; }
    }
    if (reached != count) return -1;
    return startAtEachNode(input, 0);
}
