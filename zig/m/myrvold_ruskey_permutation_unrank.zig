pub export fn myrvold_ruskey_permutation_unrank(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 2 or length > 3) return -1;
    if (length != 2) return -1;
    const n_value = input[0];
    const rank_value = input[1];
    if (n_value < 0 or n_value > 8 or rank_value < 0) return -1;
    const n: usize = @intCast(n_value);
    var factorial: i64 = 1;
    var factor: usize = 2;
    while (factor <= n) : (factor += 1) factorial *= @intCast(factor);
    if (rank_value >= factorial) return -1;

    const required = n * 8;
    if (output == null or capacity < required) return -2;
    var permutation = [_]i64{0} ** 8;
    for (0..n) |i| permutation[i] = @intCast(i);
    var remainder = rank_value;
    var size = n;
    while (size > 0) {
        const size_i64: i64 = @intCast(size);
        const choice: usize = @intCast(@rem(remainder, size_i64));
        remainder = @divTrunc(remainder, size_i64);
        const held = permutation[size - 1];
        permutation[size - 1] = permutation[choice];
        permutation[choice] = held;
        size -= 1;
    }
    for (0..n) |i| {
        const value: u64 = @intCast(permutation[i]);
        for (0..8) |byte| {
            const shift: u6 = @intCast(byte * 8);
            output[8 * i + byte] = @truncate((value >> shift) & 255);
        }
    }
    return @intCast(required);
}
