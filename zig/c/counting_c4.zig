const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 12;
const MAX_INPUT_LENGTH: usize = 26;
const MAX_OUTPUT_BYTES: usize = 96;

export fn counting_c4(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?;
    const n_value = values[0];
    const m_value = values[1];
    if (n_value < 2 or n_value > @as(i64, @intCast(MAX_VERTICES)) or
        m_value < 1 or m_value > @as(i64, @intCast(MAX_EDGES))) return -1;
    const n: usize = @intCast(n_value);
    const edge_count: usize = @intCast(m_value);
    if (length != 2 + 2 * edge_count) return -1;

    var multiplicity = [_][MAX_VERTICES]i64{[_]i64{0} ** MAX_VERTICES} ** MAX_VERTICES;
    for (0..edge_count) |edge| {
        const u_value = values[2 + 2 * edge];
        const v_value = values[3 + 2 * edge];
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value)
            return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        multiplicity[u][v] += 1;
        multiplicity[v][u] += 1;
    }

    var answers = [_]u64{0} ** MAX_EDGES;
    for (0..edge_count) |edge| {
        const u: usize = @intCast(values[2 + 2 * edge]);
        const v: usize = @intCast(values[3 + 2 * edge]);
        for (0..n) |a| {
            if (a == u or a == v) continue;
            for (0..n) |b| {
                if (b == u or b == v or b == a) continue;
                answers[edge] += @as(u64, @intCast(multiplicity[u][a] * multiplicity[a][b] * multiplicity[b][v]));
            }
        }
    }

    const bytes = 8 * edge_count;
    if (output == null or output_capacity < bytes) return -2;
    var staged = [_]u8{0} ** MAX_OUTPUT_BYTES;
    for (0..edge_count) |edge| {
        for (0..8) |byte| staged[8 * edge + byte] = @truncate(answers[edge] >> (8 * byte));
    }
    const out = output.?;
    for (0..bytes) |byte| out[byte] = staged[byte];
    return @intCast(bytes);
}
