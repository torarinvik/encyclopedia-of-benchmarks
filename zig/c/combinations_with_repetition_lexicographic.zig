fn multisetCount(n: usize, r: usize) usize {
    if (r == 0) return 1;
    if (n == 0) return 0;
    const top = n + r - 1;
    var result: usize = 1;
    for (1..r + 1) |index| result = result * (top - r + index) / index;
    return result;
}

export fn combinations_with_repetition_lexicographic(raw: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const input = raw orelse return -1;
    if (length != 2) return -1;
    if (input[0] < 0 or input[0] > 4 or input[1] < 0 or input[1] > 4) return -1;
    const n: usize = @intCast(input[0]);
    const r: usize = @intCast(input[1]);
    const count = multisetCount(n, r);
    const byte_count = 2 + count * r;
    const destination = output orelse return -2;
    if (capacity < byte_count) return -2;

    destination[0] = @truncate(count & 255);
    destination[1] = @truncate((count >> 8) & 255);
    var current = [_]u8{0} ** 4;
    for (0..count) |ordinal| {
        for (0..r) |position| destination[2 + ordinal * r + position] = current[position];
        if (ordinal + 1 == count or r == 0) continue;
        var position = r;
        while (current[position - 1] == n - 1) position -= 1;
        position -= 1;
        current[position] += 1;
        for (position + 1..r) |suffix| current[suffix] = current[position];
    }
    return @intCast(byte_count);
}
