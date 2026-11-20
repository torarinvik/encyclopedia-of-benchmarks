const MAX_INPUT: usize = 10;

fn storeI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[offset + b] = @truncate(bits >> @intCast(8 * b));
}

export fn order_preserving_huffman_greedy_trace(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT) return -1;
    const raw_n = input[0];
    if (raw_n < 2 or raw_n > 8 or length != @as(usize, @intCast(raw_n)) + 1) return -1;
    const n: usize = @intCast(raw_n);
    var weights: [15]i64 = [_]i64{0} ** 15;
    var left: [15]i32 = [_]i32{-1} ** 15;
    var right: [15]i32 = [_]i32{-1} ** 15;
    var active: [8]usize = undefined;
    var total: i64 = 0;
    for (0..n) |i| {
        const w = input[i + 1];
        if (w < 1 or w > 15) return -1;
        weights[i] = w; total += w; active[i] = i;
    }
    if (total > 120) return -1;
    var count = n;
    var next_node = n;
    while (count > 1) {
        var pair: usize = 0;
        var best = weights[active[0]] + weights[active[1]];
        for (1..count - 1) |i| {
            const candidate = weights[active[i]] + weights[active[i + 1]];
            if (candidate < best) { pair = i; best = candidate; }
        }
        const a = active[pair];
        const b = active[pair + 1];
        weights[next_node] = best; left[next_node] = @intCast(a); right[next_node] = @intCast(b);
        var i = pair;
        while (i + 2 < count) : (i += 1) active[i] = active[i + 2];
        count -= 2;
        i = count;
        while (i > pair) : (i -= 1) active[i] = active[i - 1];
        active[pair] = next_node;
        count += 1; next_node += 1;
    }
    var depths: [8]i64 = [_]i64{0} ** 8;
    var node_stack: [16]usize = undefined;
    var depth_stack: [16]i64 = undefined;
    var top: usize = 1;
    node_stack[0] = active[0]; depth_stack[0] = 0;
    while (top > 0) {
        top -= 1;
        const node = node_stack[top];
        const depth = depth_stack[top];
        if (node < n) depths[node] = depth else {
            node_stack[top] = @intCast(left[node]); depth_stack[top] = depth + 1; top += 1;
            node_stack[top] = @intCast(right[node]); depth_stack[top] = depth + 1; top += 1;
        }
    }
    var words: [10]i64 = [_]i64{0} ** 10;
    words[0] = raw_n;
    for (0..n) |j| { words[1] += input[j + 1] * depths[j]; words[j + 2] = depths[j]; }
    const needed = 8 * (n + 2);
    var staged: [80]u8 = [_]u8{0} ** 80;
    for (0..n + 2) |j| storeI64(&staged[0], 8 * j, words[j]);
    if (output == null or capacity < needed) return -2;
    for (0..needed) |j| output[j] = staged[j];
    return @intCast(needed);
}
