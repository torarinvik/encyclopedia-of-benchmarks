export fn hamming_weight(value: i64) i64 {
    if (value < 0 or value > 4_294_967_295) return -1;
    return @popCount(@as(u32, @intCast(value)));
}
