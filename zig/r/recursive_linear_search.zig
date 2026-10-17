const MAX_N: usize = 64;

fn searchRecursive(items: *const [MAX_N]i32, left: isize, right: isize, target: i32) i64 {
    if (left > right) return -1;
    if (items[@intCast(left)] == target) return @intCast(left);
    if (items[@intCast(right)] == target) return @intCast(right);
    return searchRecursive(items, left + 1, right - 1, target);
}

export fn recursive_linear_search(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > MAX_N + 2) return -1;
    const values = input.?;
    if (values[0] < 2 or values[0] > MAX_N) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 2 or values[1] < -2147483648 or values[1] > 2147483647) return -1;
    var items: [MAX_N]i32 = undefined;
    for (0..n) |i| {
        if (values[i + 2] < -2147483648 or values[i + 2] > 2147483647) return -1;
        items[i] = @intCast(values[i + 2]);
        for (0..i) |j| if (items[j] == items[i]) return -1;
    }
    return searchRecursive(&items, 0, @intCast(n) - 1, @intCast(values[1]));
}
