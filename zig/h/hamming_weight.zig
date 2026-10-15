export fn hamming_weight(value: i64) i64 {
    if (value < 0 or value > 4_294_967_295) return -1;
    const number: u32 = @intCast(value);
    var count: i64 = 0;
    for (0..32) |bit| {
        count += @as(i64, @intCast((number >> @intCast(bit)) & 1));
    }
    return count;
}
