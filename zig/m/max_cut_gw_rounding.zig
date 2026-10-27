const max_n: usize = 16;
const max_m: usize = 120;
const max_d: usize = 4;
const max_input: usize = 431;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn max_cut_gw_rounding(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0]; const m64 = input[1]; const d64 = input[2];
    if (n64 < 2 or n64 > 16 or m64 < 0 or m64 > 120 or d64 < 1 or d64 > 4 or
        length != 3 + 3 * @as(usize, @intCast(m64)) + @as(usize, @intCast(n64 * d64 + d64))) return -1;
    const n: usize = @intCast(n64); const m: usize = @intCast(m64); const d: usize = @intCast(d64);
    var edge_u: [max_m]i64 = [_]i64{0} ** max_m;
    var edge_v: [max_m]i64 = [_]i64{0} ** max_m;
    var edge_weight: [max_m]i64 = [_]i64{0} ** max_m;
    var previous_u: i64 = -1; var previous_v: i64 = -1;
    for (0..m) |edge| {
        const u = input[3 + 3 * edge]; const v = input[4 + 3 * edge]; const weight = input[5 + 3 * edge];
        if (u < 0 or v <= u or v >= n64 or weight < 1 or weight > 10000 or
            u < previous_u or (u == previous_u and v <= previous_v)) return -1;
        previous_u = u; previous_v = v;
        edge_u[edge] = u; edge_v[edge] = v; edge_weight[edge] = weight;
    }
    const vector_offset = 3 + 3 * m;
    var vectors: [max_n][max_d]i64 = [_][max_d]i64{[_]i64{0} ** max_d} ** max_n;
    var normal: [max_d]i64 = [_]i64{0} ** max_d;
    var common_norm: i64 = 0;
    for (0..n) |vertex| {
        var norm: i64 = 0;
        for (0..d) |axis| {
            const coordinate = input[vector_offset + vertex * d + axis];
            if (coordinate < -100 or coordinate > 100) return -1;
            vectors[vertex][axis] = coordinate;
            norm += coordinate * coordinate;
        }
        if (vertex == 0) common_norm = norm else if (norm != common_norm) return -1;
    }
    if (common_norm == 0) return -1;
    var has_normal = false;
    for (0..d) |axis| {
        normal[axis] = input[vector_offset + n * d + axis];
        if (normal[axis] < -100 or normal[axis] > 100) return -1;
        has_normal = has_normal or normal[axis] != 0;
    }
    if (!has_normal) return -1;
    const output_bytes = 8 * (n + 1);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var side: [max_n]i64 = [_]i64{0} ** max_n;
    for (0..n) |vertex| {
        var projection: i64 = 0;
        for (0..d) |axis| projection += vectors[vertex][axis] * normal[axis];
        if (projection > 0) side[vertex] = 1;
    }
    var cut: i64 = 0;
    for (0..m) |edge| {
        if (side[@intCast(edge_u[edge])] != side[@intCast(edge_v[edge])]) cut += edge_weight[edge];
    }
    storeI64LE(output, 0, cut);
    for (0..n) |vertex| storeI64LE(output, 8 * (vertex + 1), side[vertex]);
    return @intCast(output_bytes);
}
