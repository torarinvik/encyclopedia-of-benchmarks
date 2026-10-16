export fn inversions(values: ?[*]const i64, length: usize) i64 {
    if (length > 1024 or (length != 0 and values == null)) return -1;
    for (0..length) |i| { if (values.?[i] < -2147483648 or values.?[i] > 2147483647) return -1; }
    var count: i64 = 0;
    for (0..length) |i| { for (i + 1..length) |j| { if (values.?[i] > values.?[j]) count += 1; } }
    return count;
}
