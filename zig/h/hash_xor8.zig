export fn hash_xor8(values: [*]const i64, length: usize) i64 {
    if (length > 100001) return -1;
    for (0..length) |i| {
        if (values[i] == 0) break;
        if (values[i] < 0 or values[i] > 127) return -1;
    }
    var hash: u32 = 0;
    for (0..length) |i| {
        if (values[i] == 0) break;
        hash = (hash + @as(u32, @intCast(values[i]))) & 0xff;
    }
    return @intCast(((hash ^ 0xff) + 1) & 0xff);
}
