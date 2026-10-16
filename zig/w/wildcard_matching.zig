/// Full-string wildcard matching for lowercase ASCII text.
export fn wildcard_matching(input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 35) return -1;
    if (input[0] < 0 or input[0] > 12 or input[1] < 0 or input[1] > 20) return -1;
    const text_length: usize = @intCast(input[0]);
    const pattern_length: usize = @intCast(input[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (0..text_length) |i| {
        if (input[2 + i] < 97 or input[2 + i] > 122) return -1;
    }
    const pattern_start = 2 + text_length;
    for (0..pattern_length) |j| {
        const token = input[pattern_start + j];
        if (!((token >= 97 and token <= 122) or token == 42 or token == 63)) return -1;
    }

    var dp: [13][21]bool = @splat(@splat(false));
    dp[0][0] = true;
    for (1..pattern_length + 1) |column| {
        if (input[pattern_start + column - 1] == 42) dp[0][column] = dp[0][column - 1];
    }
    for (1..text_length + 1) |row| {
        for (1..pattern_length + 1) |column| {
            const token = input[pattern_start + column - 1];
            if (token == input[1 + row] or token == 63) {
                dp[row][column] = dp[row - 1][column - 1];
            } else if (token == 42) {
                dp[row][column] = dp[row - 1][column] or dp[row][column - 1];
            }
        }
    }
    return if (dp[text_length][pattern_length]) 1 else 0;
}
