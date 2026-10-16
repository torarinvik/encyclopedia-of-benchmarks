const max_vertices: usize = 32;
const max_edge_pairs: usize = 512;
const max_validation_length: usize = 2 + 2 * max_edge_pairs + 1;
const output_bytes_per_vertex: usize = 8;

fn vertexBit(vertex: usize) u64 {
    return @as(u64, 1) << @intCast(vertex);
}

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..output_bytes_per_vertex) |byte| {
        output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
    }
}

export fn welsh_powell(input: [*c]const i64, length: usize,
                       output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > max_validation_length) return -1;
    const n64 = input[0];
    const edge_count64 = input[1];
    if (n64 < 0 or n64 > @as(i64, @intCast(max_vertices)) or
        edge_count64 < 0 or edge_count64 > @as(i64, @intCast(max_edge_pairs))) return -1;
    const n: usize = @intCast(n64);
    const edge_count: usize = @intCast(edge_count64);
    if (length != 2 + 2 * edge_count) return -1;

    var adjacency: [max_vertices]u64 = @splat(0);
    for (0..edge_count) |edge| {
        const left64 = input[2 + 2 * edge];
        const right64 = input[3 + 2 * edge];
        if (left64 < 0 or left64 >= n64 or right64 < 0 or right64 >= n64 or left64 == right64) return -1;
        const left: usize = @intCast(left64);
        const right: usize = @intCast(right64);
        adjacency[left] |= vertexBit(right);
        adjacency[right] |= vertexBit(left);
    }

    const output_bytes = n * output_bytes_per_vertex;
    if (output == null or capacity < output_bytes) return -2;

    var degrees: [max_vertices]usize = @splat(0);
    var order: [max_vertices]usize = undefined;
    var colors: [max_vertices]i64 = @splat(-1);
    for (0..n) |vertex| {
        order[vertex] = vertex;
        for (0..n) |neighbor| {
            if ((adjacency[vertex] & vertexBit(neighbor)) != 0) degrees[vertex] += 1;
        }
    }

    // Stable descending degree order keeps equal-degree vertices by index.
    for (1..n) |index| {
        const key = order[index];
        var position = index;
        while (position > 0 and degrees[order[position - 1]] < degrees[key]) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = key;
    }

    var colored_vertices: u64 = 0;
    for (0..n) |index| {
        const vertex = order[index];
        if (colors[vertex] >= 0) continue;
        var used_colors: u64 = 0;
        for (0..n) |neighbor| {
            if ((adjacency[vertex] & vertexBit(neighbor)) != 0 and colors[neighbor] >= 0) {
                used_colors |= vertexBit(@intCast(colors[neighbor]));
            }
        }
        var color: usize = 0;
        while ((used_colors & vertexBit(color)) != 0) color += 1;
        colors[vertex] = @intCast(color);
        colored_vertices |= vertexBit(vertex);
        for (0..n) |other_index| {
            const other = order[other_index];
            if (colors[other] < 0 and (adjacency[other] & colored_vertices) == 0) {
                colors[other] = @intCast(color);
                colored_vertices |= vertexBit(other);
            }
        }
    }

    for (0..n) |vertex| putI64Le(output, vertex * output_bytes_per_vertex, colors[vertex]);
    return @intCast(output_bytes);
}
