const MAX_N: usize = 128;
const MAX_INPUT_LENGTH: usize = MAX_N + 1;

export fn reverse_a_linked_list(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input_ptr = input.?;
    const n_value = input_ptr[0];
    if (n_value < 0 or n_value > MAX_N) return -1;
    const n: usize = @intCast(n_value);
    if (length != n + 1) return -1;
    for (0..n) |i| if (input_ptr[i + 1] < -2147483648 or input_ptr[i + 1] > 2147483647) return -1;
    const output_bytes = 4 * n;
    if (output == null or capacity < output_bytes) return -2;

    var nodes: [MAX_N]i32 = undefined;
    var next: [MAX_N]i32 = undefined;
    var head: i32 = -1;
    for (0..n) |i| {
        nodes[i] = @intCast(input_ptr[i + 1]);
        next[i] = -1;
        if (head < 0) head = @intCast(i) else {
            var tail = head;
            while (next[@intCast(tail)] >= 0) tail = next[@intCast(tail)];
            next[@intCast(tail)] = @intCast(i);
        }
    }
    var previous: i32 = -1;
    var current = head;
    while (current >= 0) {
        const next_node = next[@intCast(current)];
        next[@intCast(current)] = previous;
        previous = current;
        current = next_node;
    }
    head = previous;
    const output_ptr = output.?;
    for (0..n) |index| {
        var node = head;
        for (0..index) |_| node = next[@intCast(node)];
        const bits: u32 = @bitCast(nodes[@intCast(node)]);
        for (0..4) |byte| output_ptr[index * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(output_bytes);
}
