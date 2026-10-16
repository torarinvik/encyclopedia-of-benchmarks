const max_vertices: usize = 8;
const max_colors: i64 = 4;
const max_validation_length: usize = 11;
const output_bytes: usize = 8;

fn countFrom(masks: *const [max_vertices]u8, colors: *[max_vertices]u8,
             vertex_count: usize, color_count: usize, vertex: usize) i64 {
    if (vertex == vertex_count) return 1;
    var count: i64 = 0;
    for (0..color_count) |color| {
        var safe = true;
        for (0..vertex) |prior| {
			if ((masks[vertex] & (@as(u8, 1) << @intCast(prior))) != 0 and
				@as(usize, colors[prior]) == color) {
                safe = false;
                break;
            }
        }
        if (safe) {
            colors[vertex] = @intCast(color);
            count += countFrom(masks, colors, vertex_count, color_count, vertex + 1);
        }
    }
    return count;
}

export fn graph_coloring(input: [*c]const i64, length: usize,
                         output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > max_validation_length) return -1;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > @as(i64, @intCast(max_vertices)) or m64 < 1 or m64 > max_colors) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (length != n + 2) return -1;

    var masks: [max_vertices]u8 = @splat(0);
    for (0..n) |vertex| {
        const row = input[2 + vertex];
        if (row < 0 or row >= (@as(i64, 1) << @intCast(n))) return -1;
        masks[vertex] = @intCast(row);
        if ((masks[vertex] & (@as(u8, 1) << @intCast(vertex))) != 0) return -1;
    }
    for (0..n) |vertex| {
        for (0..n) |neighbor| {
            const edge = (masks[vertex] & (@as(u8, 1) << @intCast(neighbor))) != 0;
            const reverse_edge = (masks[neighbor] & (@as(u8, 1) << @intCast(vertex))) != 0;
            if (edge != reverse_edge) return -1;
        }
    }
    if (output == null or capacity < output_bytes) return -2;

    var colors: [max_vertices]u8 = @splat(0);
    const count: u64 = @intCast(countFrom(&masks, &colors, n, m, 0));
    for (0..output_bytes) |byte| output[byte] = @truncate(count >> @intCast(8 * byte));
    return @intCast(output_bytes);
}
