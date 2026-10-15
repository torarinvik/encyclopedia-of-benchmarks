/// Check whether the packed values match the generated Golomb prefix.
const MAX_N: usize = 1024;

export fn golomb_sequence_validator(raw_input: [*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_N) return -1;
    const input = raw_input[0..length];
    if (input[0] < 1 or input[0] > MAX_N) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n) return -1;
    for (input[1..]) |value| {
        if (value < -2147483648 or value > 2147483647) return -1;
    }

    var dp: [MAX_N]i64 = @splat(0);
    dp[0] = 1;
    for (1..n) |i| {
        const previous: usize = @intCast(dp[i - 1]);
        const nested: usize = @intCast(dp[previous]);
        const source = i - nested;
        dp[i] = 1 + dp[source];
    }
    for (1..n) |index| {
        if (input[index] != dp[index]) return 0;
    }
    return 1;
}
