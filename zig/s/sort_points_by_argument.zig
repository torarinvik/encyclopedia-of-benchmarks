const MAX_N: usize = 64;
const INPUT_MAX: usize = 129;

fn half(x: i64, y: i64) i32 {
    if (y < 0) return 0;
    if (y == 0 and x >= 0) return 1;
    return 2;
}
fn less(ax: i64, ay: i64, bx: i64, by: i64) bool {
    const ah = half(ax, ay);
    const bh = half(bx, by);
    if (ah != bh) return ah < bh;
    const cross = ax * by - ay * bx;
    if (cross != 0) return cross > 0;
    const ar = ax * ax + ay * ay;
    const br = bx * bx + by * by;
    if (ar != br) return ar < br;
    if (ax != bx) return ax < bx;
    return ay < by;
}
fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn sort_points_by_argument(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 1 or length > INPUT_MAX) return -1;
    const nr = input[0];
    if (nr < 1 or nr > @as(i64, @intCast(MAX_N)) or length != 1 + 2 * @as(usize, @intCast(nr))) return -1;
    const n: usize = @intCast(nr);
    var xs = [_]i64{0} ** MAX_N;
    var ys = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        const x = input[1 + 2 * i];
        const y = input[2 + 2 * i];
        if (x < -1_000_000_000 or x > 1_000_000_000 or y < -1_000_000_000 or y > 1_000_000_000) return -1;
        xs[i] = x;
        ys[i] = y;
    }
    const required = 16 * n;
    const output = output_opt orelse return -2;
    if (capacity < required) return -2;
    for (1..n) |i| {
        const item_x = xs[i];
        const item_y = ys[i];
        var j = i;
        while (j > 0 and less(item_x, item_y, xs[j - 1], ys[j - 1])) : (j -= 1) {
            xs[j] = xs[j - 1];
            ys[j] = ys[j - 1];
        }
        xs[j] = item_x;
        ys[j] = item_y;
    }
    for (0..n) |i| {
        storeLe(output, 16 * i, xs[i]);
        storeLe(output, 16 * i + 8, ys[i]);
    }
    return @intCast(required);
}
