const MAX_VALUES: usize = 128;

export fn longest_palindromic_subsequence(values: [*]const i64, length: usize) i64 {
    if (length > MAX_VALUES) return -1;
    if (length == 0) return 0;
    var dp: [MAX_VALUES]i64 = undefined;
    for (0..MAX_VALUES) |index| dp[index] = 0;
    var start = length;
    while (start > 0) {
        start -= 1;
        dp[start] = 1;
        var diagonal: i64 = 0;
        for (start + 1..length) |finish| {
            const previous = dp[finish];
            if (values[start] == values[finish]) {
                dp[finish] = diagonal + 2;
            } else {
                dp[finish] = @max(dp[finish], dp[finish - 1]);
            }
            diagonal = previous;
        }
    }
    return dp[length - 1];
}
