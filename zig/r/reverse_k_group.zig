const MAX_N: usize = 256;
const MAX_INPUT_LENGTH: usize = MAX_N + 2;

export fn reverse_k_group(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input_ptr = input.?;
    const n_value = input_ptr[0];
    const k_value = input_ptr[1];
    if (n_value < 0 or n_value > MAX_N or k_value < 1 or k_value > MAX_N) return -1;
    const n: usize = @intCast(n_value);
    const k: usize = @intCast(k_value);
    if (length != n + 2) return -1;
    const output_bytes = 8 * n;
    if (output == null or capacity < output_bytes) return -2;

    var nodes: [MAX_N]i64 = undefined;
    var next: [MAX_N + 1]i32 = undefined;
    var head: i32 = -1;
    for (0..n) |i| {
        nodes[i] = input_ptr[i + 2];
        next[i] = -1;
        if (head < 0) head = @intCast(i) else {
            var tail = head;
            while (next[@intCast(tail)] >= 0) tail = next[@intCast(tail)];
            next[@intCast(tail)] = @intCast(i);
        }
    }
    var remaining: usize = 0;
    var node = head;
    while (node >= 0) : (node = next[@intCast(node)]) remaining += 1;
    const dummy = MAX_N;
    next[dummy] = head;
    var previous: i32 = @intCast(dummy);
    while (remaining >= k) {
        const current = next[@intCast(previous)];
        var moved = next[@intCast(current)];
        for (1..k) |_| {
            next[@intCast(current)] = next[@intCast(moved)];
            next[@intCast(moved)] = next[@intCast(previous)];
            next[@intCast(previous)] = moved;
            moved = next[@intCast(current)];
        }
        previous = current;
        remaining -= k;
    }

    var result: [MAX_N]i64 = undefined;
    var index: usize = 0;
    node = next[dummy];
    while (node >= 0) : (node = next[@intCast(node)]) {
        result[index] = nodes[@intCast(node)];
        index += 1;
    }
    const output_ptr = output.?;
    for (0..n) |i| {
        const bits: u64 = @bitCast(result[i]);
        for (0..8) |byte| output_ptr[i * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(output_bytes);
}
