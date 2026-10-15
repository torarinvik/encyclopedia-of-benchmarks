export fn is_sorted(input: ?[*]const i64, length: usize) i64 {
    if (length > 4096 or (length != 0 and input == null)) return -1;
    if (length == 0) return 1;
    const values = input.?[0..length];
    for (values) |value| {
        if (value < -2_147_483_648 or value > 2_147_483_647) return -1;
    }
    for (1..length) |index| {
        if (values[index] < values[index - 1]) return 0;
    }
    return 1;
}
