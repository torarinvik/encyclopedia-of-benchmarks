const MAX_N: usize = 256;
const MAX_INPUT_LENGTH: usize = MAX_N + 1;

export fn reverse_linked_list(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input_ptr = input.?;
    const n_value = input_ptr[0];
    if (n_value < 1 or n_value > MAX_N) return -1;
    const n: usize = @intCast(n_value);
    if (length != n + 1) return -1;
    const output_bytes = 8 * n;
    if (output == null or capacity < output_bytes) return -2;

    var nodes: [MAX_N]i64 = undefined;
    var next: [MAX_N]i32 = undefined;
    var previous_link: [MAX_N]i32 = undefined;
    for (0..n) |i| {
        nodes[i] = input_ptr[i + 1];
        next[i] = if (i + 1 < n) @intCast(i + 1) else -1;
        previous_link[i] = if (i > 0) @intCast(i - 1) else -1;
    }
    var previous: i32 = -1;
    var current: i32 = 0;
    while (current >= 0) {
        const next_node = next[@intCast(current)];
        next[@intCast(current)] = previous;
        previous_link[@intCast(current)] = next_node;
        previous = current;
        current = next_node;
    }
    var node = previous;
    var expected_previous: i32 = -1;
    var result: [MAX_N]i64 = undefined;
    for (0..n) |i| {
        if (node < 0 or previous_link[@intCast(node)] != expected_previous) return -1;
        result[i] = nodes[@intCast(node)];
        expected_previous = node;
        node = next[@intCast(node)];
    }
    if (node >= 0) return -1;
    const output_ptr = output.?;
    for (0..n) |i| {
        const bits: u64 = @bitCast(result[i]);
        for (0..8) |byte| output_ptr[i * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(output_bytes);
}
