const MAX_TARGET: usize = 127;

fn buildPath(target: usize, parent: *[MAX_TARGET + 1]usize,
    seen: *[MAX_TARGET + 1]bool, queue: *[MAX_TARGET + 1]usize,
    reverse: *[MAX_TARGET + 1]usize, path: *[MAX_TARGET]usize) usize {
    if (target == 1) { path[0] = 1; return 1; }
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = 1;
    seen[1] = true;
    while (head < tail) {
        const current = queue[head];
        head += 1;
        var chain_length: usize = 0;
        var node = current;
        while (node != 0) {
            reverse[chain_length] = node;
            chain_length += 1;
            node = parent[node];
        }
        for (0..chain_length) |offset| {
            const ancestor = reverse[chain_length - offset - 1];
            const child = current + ancestor;
            if (child > target or seen[child]) continue;
            seen[child] = true;
            parent[child] = current;
            if (child == target) {
                var count: usize = 0;
                node = target;
                while (node != 0) {
                    path[count] = node;
                    count += 1;
                    node = parent[node];
                }
                var left: usize = 0;
                var right = count - 1;
                while (left < right) {
                    const temporary = path[left];
                    path[left] = path[right];
                    path[right] = temporary;
                    left += 1;
                    right -= 1;
                }
                return count;
            }
            queue[tail] = child;
            tail += 1;
        }
    }
    return 0;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn knuth_power_tree(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length != 1) return -1;
    const target_value = input.?[0];
    if (target_value < 1 or target_value > MAX_TARGET) return -1;
    const target: usize = @intCast(target_value);
    var parent: [MAX_TARGET + 1]usize = @splat(0);
    var seen: [MAX_TARGET + 1]bool = @splat(false);
    var queue: [MAX_TARGET + 1]usize = @splat(0);
    var reverse: [MAX_TARGET + 1]usize = @splat(0);
    var path: [MAX_TARGET]usize = @splat(0);
    const path_length = buildPath(target, &parent, &seen, &queue, &reverse, &path);
    if (path_length == 0) return -1;
    const required = 8 * (path_length + 1);
    if (output == null or output_capacity < required) return -2;
    storeI64Le(output.?, 0, @intCast(path_length - 1));
    for (0..path_length) |index| storeI64Le(output.?, 8 * (index + 1), @intCast(path[index]));
    return @intCast(required);
}
