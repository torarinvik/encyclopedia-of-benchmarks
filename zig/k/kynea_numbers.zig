export fn kynea_numbers(index: i64) i64 {
    if (index < 1 or index > 31) return -1;
    const value: i64 = (@as(i64, 1) << @as(u6, @intCast(index))) + 1;
    const square = value * value;
    return square - 2;
}
