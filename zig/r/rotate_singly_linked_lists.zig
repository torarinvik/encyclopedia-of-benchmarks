const MAX_N: usize = 64;

export fn rotate_singly_linked_lists(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_N + 2) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > MAX_N or values[1] < 0 or values[1] > 2147483647) return -1;
    const n: usize = @intCast(values[0]);
    const k = values[1];
    if (length != n + 2) return -1;
    for (0..n) |i| if (values[i + 2] < -2147483648 or values[i + 2] > 2147483647) return -1;
    const bytes = 8 * (n + 1);
    if (output == null or capacity < bytes) return -2;

    var nodes: [MAX_N]i32 = undefined;
    var next: [MAX_N]i32 = undefined;
    for (0..n) |i| {
        nodes[i] = @intCast(values[i + 2]);
        next[i] = if (i + 1 < n) @intCast(i + 1) else -1;
    }
    var head: i32 = if (n > 0) 0 else -1;
    if (n > 1 and k > 0) {
        const tail = n - 1;
        next[tail] = head;
        const shift: usize = @intCast(@rem(k, @as(i64, @intCast(n))));
        const steps = n - shift;
        var new_tail: i32 = @intCast(tail);
        for (0..steps) |_| new_tail = next[@intCast(new_tail)];
        head = next[@intCast(new_tail)];
        next[@intCast(new_tail)] = -1;
    }
    const destination = output.?;
    const count: u64 = n;
    for (0..8) |byte| destination[byte] = @truncate(count >> @intCast(byte * 8));
    var node = head;
    for (0..n) |i| {
        const bits: u64 = @bitCast(@as(i64, nodes[@intCast(node)]));
        for (0..8) |byte| destination[8 + i * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
        if (i + 1 < n) node = next[@intCast(node)];
    }
    return @intCast(bytes);
}
