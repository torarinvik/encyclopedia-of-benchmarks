const MAX_N: usize = 64;

fn reverseLinks(next: *[MAX_N]i32, previous: usize, current: usize) usize {
    if (next[current] >= 0) {
        const head = reverseLinks(next, current, @intCast(next[current]));
        next[current] = @intCast(previous);
        next[previous] = -1;
        return head;
    }
    next[current] = @intCast(previous);
    next[previous] = -1;
    return current;
}

export fn reverse_a_linked_list_using_recusion(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_N + 1) return -1;
    const values = input.?;
    if (values[0] < 2 or values[0] > MAX_N) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| if (values[i + 1] < -2147483648 or values[i + 1] > 2147483647) return -1;
    const bytes = 4 * n;
    if (output == null or capacity < bytes) return -2;

    var nodes: [MAX_N]i32 = undefined;
    var next: [MAX_N]i32 = undefined;
    for (0..n) |i| {
        nodes[i] = @intCast(values[i + 1]);
        next[i] = if (i + 1 < n) @intCast(i + 1) else -1;
    }
    var node = reverseLinks(&next, 0, @intCast(next[0]));
    const destination = output.?;
    for (0..n) |i| {
        const bits: u32 = @bitCast(nodes[node]);
        for (0..4) |byte| destination[i * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
        if (i + 1 < n) node = @intCast(next[node]);
    }
    return @intCast(bytes);
}
