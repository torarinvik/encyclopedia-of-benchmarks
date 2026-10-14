/// Return the length of a strictly increasing subsequence.
export fn longest_increasing_subsequence(values: [*]const i64, length: usize) i64 {
    if (length > 512) return -1;
    if (length == 0) return 0;

    var dp: [512]i64 = @splat(0);
    var longest: i64 = 0;
    for (0..length) |index| {
        dp[index] = 1;
        for (0..index) |previous| {
            if (values[index] > values[previous] and dp[index] < dp[previous] + 1) {
                dp[index] = dp[previous] + 1;
            }
        }
        if (dp[index] > longest) longest = dp[index];
    }
    return longest;
}
