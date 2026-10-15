/// Length of the longest arithmetic subsequence.
export fn longest_arithmetic_subsequence(values: [*]const i64, length: usize) i64 {
    if (length > 64) return -1;
    for (values[0..length]) |value| {
        if (value < -1_000_000 or value > 1_000_000) return -1;
    }
    if (length <= 1) return @intCast(length);
    var keys = [_][127]i64{[_]i64{0} ** 127} ** 64;
    var sizes = [_][127]i64{[_]i64{0} ** 127} ** 64;
    var maximum: i64 = 2;
    for (0..length) |right| {
        for (0..right) |left| {
            const difference = values[right] - values[left];
            const hash: usize = @intCast(@mod(@mod(difference, 127) + 127, 127));
            var slot = hash;
            while (sizes[left][slot] != 0 and keys[left][slot] != difference) slot = (slot + 1) % 127;
            const candidate = (if (sizes[left][slot] == 0) @as(i64, 1) else sizes[left][slot]) + 1;
            slot = hash;
            while (sizes[right][slot] != 0 and keys[right][slot] != difference) slot = (slot + 1) % 127;
            if (sizes[right][slot] == 0 or candidate > sizes[right][slot]) {
                keys[right][slot] = difference;
                sizes[right][slot] = candidate;
            }
            maximum = @max(maximum, candidate);
        }
    }
    return maximum;
}
