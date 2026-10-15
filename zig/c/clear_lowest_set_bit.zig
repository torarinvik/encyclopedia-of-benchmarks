export fn clear_lowest_set_bit(value: i64) i64 {
    if (value < 0 or value > 2147483647) return -1;
    return value & (value - 1);
}
