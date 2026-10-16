const MAX_N: usize = 256;
const VALUE_LIMIT: i64 = 1_000_000;

export fn good_pairs(packed: [*c]const i64, length: usize) i64 {
    if (packed == null or length == 0 or length > MAX_N + 1) return -1;
    const n = packed[0];
    if (n < 0 or n > @as(i64, @intCast(MAX_N)) or length != @as(usize, @intCast(n)) + 1) return -1;
    const count: usize = @intCast(n);
    for (0..count) |index| {
        const value = packed[index + 1];
        if (value < -VALUE_LIMIT or value > VALUE_LIMIT) return -1;
    }
    var pairs: i64 = 0;
    for (0..count) |i| {
        for (i + 1..count) |j| {
            if (packed[i + 1] == packed[j + 1]) pairs += 1;
        }
    }
    return pairs;
}
