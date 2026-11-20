const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_VERTICES: usize = 24;
const MAX_INPUT: usize = 97;

fn putLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn edge_colored_graph_layer_encoding(
    input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n0 = input[0];
    const m0 = input[1];
    const d0 = input[2];
    const q0 = input[3];
    if (n0 < 1 or n0 > 8 or m0 < 0 or m0 > 28 or d0 < 1 or d0 > 3 or q0 < 1 or q0 > 3) return -1;
    const n: usize = @intCast(n0);
    const m: usize = @intCast(m0);
    const layers: usize = @intCast(d0);
    const classes: usize = @intCast(q0);
    const edge_offset = 4 + n;
    if (length != edge_offset + 3 * m) return -1;
    var source_colors: [MAX_N]i64 = @splat(0);
    for (0..n) |vertex| {
        source_colors[vertex] = input[4 + vertex];
        if (source_colors[vertex] < 0 or source_colors[vertex] >= q0) return -1;
    }
    var source_edges: [MAX_N][MAX_N]u8 = @splat(@splat(0));
    var offset = edge_offset;
    for (0..m) |_| {
        var left0 = input[offset];
        var right0 = input[offset + 1];
        const color0 = input[offset + 2];
        offset += 3;
        if (left0 < 0 or left0 >= n0 or right0 < 0 or right0 >= n0 or left0 == right0
            or color0 < 1 or color0 >= (@as(i64, 1) << @intCast(d0))) return -1;
        if (left0 > right0) {
            const temp = left0;
            left0 = right0;
            right0 = temp;
        }
        const left: usize = @intCast(left0);
        const right: usize = @intCast(right0);
        if (source_edges[left][right] != 0) return -1;
        source_edges[left][right] = @intCast(color0);
    }

    const nodes = n * layers;
    var adjacency: [MAX_VERTICES][MAX_VERTICES]bool = @splat(@splat(false));
    for (0..layers) |layer| {
        const bit: u8 = @as(u8, 1) << @intCast(layer);
        for (0..n) |left| {
            var right = left + 1;
            while (right < n) : (right += 1) {
                if ((source_edges[left][right] & bit) != 0)
                    adjacency[layer * n + left][layer * n + right] = true;
            }
        }
    }
    for (0..n) |vertex| {
        for (0..(layers - 1)) |layer|
            adjacency[layer * n + vertex][(layer + 1) * n + vertex] = true;
    }
    var edge_count: usize = 0;
    for (0..nodes) |left| {
        var right = left + 1;
        while (right < nodes) : (right += 1) {
            if (adjacency[left][right]) edge_count += 1;
        }
    }
    const bytes = 8 * (2 + nodes + 2 * edge_count);
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    putLe(output, 0, @intCast(nodes));
    putLe(output, 8, @intCast(edge_count));
    var word: usize = 2;
    for (0..layers) |layer| {
        for (0..n) |vertex| {
            putLe(output, 8 * word, @intCast(layer * classes + @as(usize, @intCast(source_colors[vertex]))));
            word += 1;
        }
    }
    for (0..nodes) |left| {
        var right = left + 1;
        while (right < nodes) : (right += 1) {
            if (adjacency[left][right]) {
                putLe(output, 8 * word, @intCast(left)); word += 1;
                putLe(output, 8 * word, @intCast(right)); word += 1;
            }
        }
    }
    return @intCast(bytes);
}
