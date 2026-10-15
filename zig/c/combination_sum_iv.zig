/// Bottom-up count of ordered denomination sequences.
export fn combination_sum_iv(input_values: [*]const i64, length: usize) i64 {
    const invalid: i64 = -9223372036854775807 - 1;
    if (length < 2 or length > 18) return invalid;
    if (input_values[0] < 0 or input_values[0] > 16 or input_values[1] < 0 or input_values[1] > 63) return invalid;
    const count: usize = @intCast(input_values[0]);
    const target: usize = @intCast(input_values[1]);
    if (length != count + 2) return invalid;
    for (0..count) |i| {
        if (input_values[i + 2] < 1 or input_values[i + 2] > 63) return invalid;
        for (0..i) |j| {
            if (input_values[i + 2] == input_values[j + 2]) return invalid;
        }
    }

    var dp: [64]i64 = @splat(0);
    dp[0] = 1;
    for (1..target + 1) |sum| {
        for (0..count) |i| {
            const denomination: usize = @intCast(input_values[i + 2]);
            if (denomination <= sum) dp[sum] += dp[sum - denomination];
        }
    }
    return dp[target];
}
