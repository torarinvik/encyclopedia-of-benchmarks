const std = @import("std");
const MaxInput: usize = 67;
const MaxOutput: usize = 504;
const MaxH: usize = 63;

const Context = struct {
    concave: []const i64,
    arbitrary: []const i64,
    y_min: [MaxH]usize,
    y_max: [MaxH]usize,
    x_min: [32]usize,
    x_max: [32]usize,
    result: [MaxH]i64,
};

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn blockRows(c: *Context, x1: usize, x2: usize, y1: usize, y2: usize,
    row1: usize, row2: usize, q1: usize, q2: usize) void {
    if (row1 > row2) return;
    const mid = row1 + (row2 - row1) / 2;
    const x = x1 + mid;
    var best: i64 = std.math.maxInt(i64);
    var best_q = q1;
    var q = q1;
    while (q <= q2) : (q += 1) {
        const y = y2 - q;
        const value = c.arbitrary[y] + c.concave[x - y];
        if (value < best) { best = value; best_q = q; }
    }
    if (best < c.result[x]) c.result[x] = best;
    if (row1 < mid) blockRows(c, x1, x2, y1, y2, row1, mid - 1, q1, best_q);
    if (mid < row2) blockRows(c, x1, x2, y1, y2, mid + 1, row2, best_q, q2);
}

fn scanRectangle(c: *Context, x1: usize, x2: usize, y1: usize, y2: usize) void {
    var x = x1;
    while (x <= x2) : (x += 1) {
        const low = @max(c.y_min[x], y1);
        const high = @min(c.y_max[x], y2);
        if (low <= high) {
            var y = low;
            while (y <= high) : (y += 1) {
                const value = c.arbitrary[y] + c.concave[x - y];
                if (value < c.result[x]) c.result[x] = value;
            }
        }
    }
}

fn partition(c: *Context, x1: usize, x2: usize, y1: usize, y2: usize) void {
    if (x1 > x2 or y1 > y2) return;
    if (c.y_max[x1] >= y2 and y1 >= c.y_min[x2]) {
        blockRows(c, x1, x2, y1, y2, 0, x2 - x1, 0, y2 - y1);
        return;
    }
    if ((x2 - x1) * (y2 - y1) < 1000) { scanRectangle(c, x1, x2, y1, y2); return; }
    if (x2 - x1 > y2 - y1) {
        const mid = (x1 + x2) / 2;
        const left_y2 = @min(c.y_max[mid], y2);
        if (y1 <= left_y2) partition(c, x1, mid, y1, left_y2);
        const right_y1 = @max(c.y_min[mid], y1);
        if (right_y1 <= y2) partition(c, mid + 1, x2, right_y1, y2);
    } else {
        const mid = (y1 + y2) / 2;
        const left_x2 = @min(c.x_max[mid], x2);
        if (x1 <= left_x2) partition(c, x1, left_x2, y1, mid);
        const right_x1 = @max(c.x_min[mid], x1);
        if (right_x1 <= x2) partition(c, right_x1, x2, mid + 1, y2);
    }
}

export fn min_plus_convolution_concave_arbitrary(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MaxInput) return -1;
    const input = input_opt.?;
    const n0 = input[0]; const m0 = input[1];
    if (n0 < 1 or n0 > 32 or m0 < 1 or m0 > 32) return -1;
    const n: usize = @intCast(n0); const m: usize = @intCast(m0);
    if (length != 2 + n + m) return -1;
    const words = input[0..length];
    const a = words[2 .. 2 + n]; const b = words[2 + n ..];
    for (words[2..]) |value| if (value < 0 or value > 1_000_000_000) return -1;
    for (0..n) |i| if (i + 2 < n and a[i + 1] - a[i] < a[i + 2] - a[i + 1]) return -1;
    const h = n + m - 1; const bytes = 8 * h;
    if (bytes > MaxOutput) return -1;
    if (output_opt == null or capacity < bytes) return -2;
    var c = Context{ .concave = a, .arbitrary = b, .y_min = undefined, .y_max = undefined,
        .x_min = undefined, .x_max = undefined, .result = undefined };
    for (0..h) |x| {
        c.y_min[x] = if (x >= n) x - n + 1 else 0;
        c.y_max[x] = @min(m - 1, x);
        c.result[x] = std.math.maxInt(i64);
    }
    for (0..m) |y| { c.x_min[y] = y; c.x_max[y] = n - 1 + y; }
    partition(&c, 0, h - 1, 0, m - 1);
    const output = output_opt.?;
    for (0..h) |i| storeI64Le(output, 8 * i, c.result[i]);
    return @intCast(bytes);
}
