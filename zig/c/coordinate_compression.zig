const std = @import("std");

fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn coordinate_compression(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or input[0] < 0 or input[0] > 128) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 1) return -1;
    var sorted: [128]i64 = @splat(0);
    for (0..n) |i| {
        const value = input[i + 1];
        if (value < -2147483648 or value > 2147483647) return -1;
        sorted[i] = value;
    }
    if (capacity < n * 8 or (n > 0 and output == null)) return -2;
    std.mem.sort(i64, sorted[0..n], {}, std.sort.asc(i64));
    var ranks: [128]i64 = @splat(0);
    var rank: i64 = -1;
    for (0..n) |i| {
        if (i == 0 or sorted[i] != sorted[i - 1]) rank += 1;
        ranks[i] = rank;
    }
    for (0..n) |i| {
        var low: usize = 0;
        var high: usize = n;
        while (low < high) {
            const middle = low + (high - low) / 2;
            if (sorted[middle] < input[i + 1]) low = middle + 1 else high = middle;
        }
        putI64Le(output, i * 8, ranks[low]);
    }
    return @intCast(n * 8);
}
