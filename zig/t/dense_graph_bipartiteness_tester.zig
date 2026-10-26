const MaxN = 64;
const MaxQ = 16;
const MaxInput = 82;

fn hasEdge(row: i64, vertex: usize) bool { return ((@as(u64, @bitCast(row)) >> @intCast(vertex)) & 1) != 0; }
fn putI64(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn dense_graph_bipartiteness_tester(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MaxInput) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 64 or input[1] < 1 or input[1] > 16) return -1;
    const n: usize = @intCast(input[0]); const q: usize = @intCast(input[1]);
    if (q > n or length != 2 + n + q) return -1;
    for (0..n) |i| {
        const row = input[2 + i];
        if ((n < 64 and (row < 0 or (@as(u64, @bitCast(row)) >> @intCast(n)) != 0)) or hasEdge(row, i)) return -1;
        for (i + 1..n) |j| if (hasEdge(row, j) != hasEdge(input[2 + j], i)) return -1;
    }
    var remaining: [MaxN]usize = @splat(0); var sample: [MaxQ]usize = @splat(0);
    for (0..n) |i| remaining[i] = i;
    for (0..q) |i| {
        const draw = input[2 + n + i];
        if (draw < 0 or @as(u64, @intCast(draw)) >= n - i) return -1;
        const selected = i + @as(usize, @intCast(draw));
        const temp = remaining[i]; remaining[i] = remaining[selected]; remaining[selected] = temp;
        sample[i] = remaining[i];
    }
    var adjacent: [MaxQ][MaxQ]bool = @splat(@splat(false));
    for (0..q) |i| for (i + 1..q) |j| {
        adjacent[i][j] = hasEdge(input[2 + sample[i]], sample[j]); adjacent[j][i] = adjacent[i][j];
    };
    var color: [MaxQ]i8 = @splat(-1); var accepted: i64 = 1;
    for (0..q) |start| {
        if (color[start] != -1) continue;
        var queue: [MaxQ]usize = @splat(0); var head: usize = 0; var tail: usize = 0;
        queue[tail] = start; tail += 1; color[start] = 0;
        while (head < tail) {
            const vertex = queue[head]; head += 1;
            for (0..q) |neighbor| {
                if (!adjacent[vertex][neighbor]) continue;
                if (color[neighbor] == -1) { color[neighbor] = color[vertex] ^ 1; queue[tail] = neighbor; tail += 1; }
                else if (color[neighbor] == color[vertex]) accepted = 0;
            }
        }
    }
    if (output_opt == null or capacity < 16) return -2;
    var staged: [16]u8 = @splat(0); putI64(&staged, 0, accepted); putI64(&staged, 8, @intCast(q * (q - 1) / 2));
    const output = output_opt.?; @memcpy(output[0..16], staged[0..16]);
    return 16;
}
