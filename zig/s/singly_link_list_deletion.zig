const MAX_N: usize = 64;

export fn singly_link_list_deletion(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_N + 2) return -1;
    const values = input.?;
    if (values[0] < 1 or values[0] > MAX_N) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 2 or values[1] < 1 or values[1] > @as(i64, @intCast(n))) return -1;
    for (0..n) |i| if (values[i + 2] < -2147483648 or values[i + 2] > 2147483647) return -1;
    const bytes = 4 * (n - 1);
    if (output == null or capacity < bytes) return -2;

    var nodes: [MAX_N]i32 = undefined;
    var next: [MAX_N]i32 = undefined;
    for (0..n) |i| {
        nodes[i] = @intCast(values[i + 2]);
        next[i] = if (i + 1 < n) @intCast(i + 1) else -1;
    }
    var head: i32 = 0;
    const position: usize = @intCast(values[1]);
    if (position == 1) head = next[0] else {
        var previous: usize = 0;
        for (2..position) |_| previous = @intCast(next[previous]);
        const removed: usize = @intCast(next[previous]);
        next[previous] = next[removed];
    }
    const destination = output.?;
    var node = head;
    for (0..n - 1) |i| {
        const node_index: usize = @intCast(node);
        const bits: u32 = @bitCast(nodes[node_index]);
        for (0..4) |byte| destination[i * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
        if (i + 1 < n - 1) node = next[node_index];
    }
    return @intCast(bytes);
}
