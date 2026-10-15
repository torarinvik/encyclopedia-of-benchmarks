export fn clear_leftmost_set_bit(value: i64) i64 {
    if (value < 0 or value > 2147483647) return -1;
    if (value == 0) return 0;
    var temp = value;
    var position: i64 = 0;
    while (temp > 0) {
        temp >>= 1;
        position += 1;
    }
    const mask = ~(@as(i64, 1) << @as(u6, @intCast(position - 1)));
    return value & mask;
}
