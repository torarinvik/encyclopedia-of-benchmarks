const std = @import("std");

const MaxInput: usize = 259;
const MaxOutput: usize = 2040;
const MaxN: usize = 128;
const MaxM: usize = 128;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn isConvex(values: []const i64) bool {
    for (0..values.len) |i| {
        if (i + 2 < values.len and values[i + 1] - values[i] > values[i + 2] - values[i + 1])
            return false;
    }
    return true;
}

export fn min_plus_convolution_convex_convex(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MaxInput) return -1;
    const input = input_opt.?;
    const n0 = input[0];
    const m0 = input[1];
    if (n0 < 1 or n0 > 128 or m0 < 1 or m0 > 128) return -1;
    const n: usize = @intCast(n0);
    const m: usize = @intCast(m0);
    if (length != 2 + n + m) return -1;
    const words = input[0..length];
    const a = words[2 .. 2 + n];
    const b = words[2 + n .. 2 + n + m];
    for (words[2..]) |value| if (value < 0 or value > 1_000_000_000) return -1;
    if (!isConvex(a) or !isConvex(b)) return -1;

    const count = n + m - 1;
    const bytes = 8 * count;
    if (bytes > MaxOutput) return -1;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;

    var result: [MaxN + MaxM - 1]i64 = undefined;
    result[0] = a[0] + b[0];
    var ai: usize = 0;
    var bi: usize = 0;
    var out: usize = 1;
    while (ai + 1 < n or bi + 1 < m) {
        var slope: i64 = 0;
        if (bi + 1 == m or (ai + 1 < n and a[ai + 1] - a[ai] <= b[bi + 1] - b[bi])) {
            slope = a[ai + 1] - a[ai];
            ai += 1;
        } else {
            slope = b[bi + 1] - b[bi];
            bi += 1;
        }
        result[out] = result[out - 1] + slope;
        out += 1;
    }
    for (0..count) |i| storeI64Le(output, 8 * i, result[i]);
    return @intCast(bytes);
}
