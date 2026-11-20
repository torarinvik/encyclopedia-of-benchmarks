const MAX_N: usize = 8;
const MAX_M: usize = 12;
const MAX_INPUT: usize = 111;

fn putLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn hypergraph_incidence_graph_encoding(
    input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 8 or m64 < 0 or m64 > 12) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var incidence: [MAX_N][MAX_M]bool = @splat(@splat(false));
    var offset: usize = 2;
    for (0..m) |edge| {
        if (offset >= length) return -1;
        const size64 = input[offset];
        offset += 1;
        if (size64 < 0 or size64 > n64 or @as(usize, @intCast(size64)) > length - offset) return -1;
        const size: usize = @intCast(size64);
        for (0..size) |_| {
            const vertex64 = input[offset];
            offset += 1;
            if (vertex64 < 0 or vertex64 >= n64) return -1;
            const vertex: usize = @intCast(vertex64);
            if (incidence[vertex][edge]) return -1;
            incidence[vertex][edge] = true;
        }
    }
    if (offset != length) return -1;

    var count: usize = 0;
    for (0..n) |vertex| for (0..m) |edge| {
        if (incidence[vertex][edge]) count += 1;
    };
    const nodes = n + m;
    const bytes = 8 * (2 + nodes + 2 * count);
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    putLe(output, 0, @intCast(nodes));
    putLe(output, 8, @intCast(count));
    var word: usize = 2;
    for (0..n) |_| { putLe(output, 8 * word, 0); word += 1; }
    for (0..m) |_| { putLe(output, 8 * word, 1); word += 1; }
    for (0..n) |vertex| for (0..m) |edge| {
        if (incidence[vertex][edge]) {
            putLe(output, 8 * word, @intCast(vertex)); word += 1;
            putLe(output, 8 * word, @intCast(n + edge)); word += 1;
        }
    };
    return @intCast(bytes);
}
