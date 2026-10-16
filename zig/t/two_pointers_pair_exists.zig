export fn two_pointers_pair_exists(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 258) return -1;
    const values = input.?;
    const target = values[0];
    const n = values[1];
    if (n < 0 or n > 256 or length != 2 + @as(usize, @intCast(n))) return -1;
    if (target < -2000000 or target > 2000000) return -1;
    const count: usize = @intCast(n);
    for (0..count) |i| {
        const value = values[2 + i];
        if (value < -1000000 or value > 1000000) return -1;
        if (i > 0 and values[1 + i] > value) return -1;
    }
    if (n < 2) return 0;
    var left: usize = 0;
    var right = count - 1;
    while (left < right) {
        const sum = values[2 + left] + values[2 + right];
        if (sum == target) return 1;
        if (sum < target) left += 1 else right -= 1;
    }
    return 0;
}
