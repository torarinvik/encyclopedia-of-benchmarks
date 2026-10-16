const MAX_VERTICES: i64 = 64;
const MAX_EDGES: i64 = 256;

fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
}

pub export fn graph_rust_weighted(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const nv = input[0];
    const mv = input[1];
    if (nv < 0 or nv > MAX_VERTICES or mv < 0 or mv > MAX_EDGES
        or length != 2 + 3 * @as(usize, @intCast(mv))) return -1;
    const n: usize = @intCast(nv);
    const m: usize = @intCast(mv);
    for (0..m) |edge| {
        const u = input[2 + 3 * edge];
        const v = input[3 + 3 * edge];
        const weight = input[4 + 3 * edge];
        if (u < 0 or u >= nv or v < 0 or v >= nv or weight < -2147483648 or weight > 2147483647) return -1;
    }
    const required = (1 + n + 4 * m) * 8;
    if (output == null or capacity < required) return -2;
    var cursor: usize = 0;
    putI64(output, cursor * 8, nv);
    cursor += 1;
    for (0..n) |vertex| {
        var degree: usize = 0;
        for (0..m) |edge| {
            if (input[2 + 3 * edge] == @as(i64, @intCast(vertex))) degree += 1;
            if (input[3 + 3 * edge] == @as(i64, @intCast(vertex))) degree += 1;
        }
        putI64(output, cursor * 8, @intCast(degree));
        cursor += 1;
        for (0..m) |edge| {
            const u = input[2 + 3 * edge];
            const v = input[3 + 3 * edge];
            const weight = input[4 + 3 * edge];
            if (u == @as(i64, @intCast(vertex))) {
                putI64(output, cursor * 8, v);
                cursor += 1;
                putI64(output, cursor * 8, weight);
                cursor += 1;
            }
            if (v == @as(i64, @intCast(vertex))) {
                putI64(output, cursor * 8, u);
                cursor += 1;
                putI64(output, cursor * 8, weight);
                cursor += 1;
            }
        }
    }
    return @intCast(required);
}
