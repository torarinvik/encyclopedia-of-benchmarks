/// Return the LCS length of two packed ASCII sequences.
export fn longest_common_subsequence(input_values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 512) return -1;
    const left_length = input_values[0];
    const right_length = input_values[1];
    if (left_length < 0 or left_length > 255 or right_length < 0 or right_length > 255) return -1;
    if (length != 2 + @as(usize, @intCast(left_length)) + @as(usize, @intCast(right_length))) return -1;
    for (0..@as(usize, @intCast(left_length + right_length))) |index| {
        const value = input_values[2 + index];
        if (value < 0 or value > 127) return -1;
    }

    const left_start: usize = 2;
    const right_start: usize = left_start + @as(usize, @intCast(left_length));
    var dp: [256]i64 = @splat(0);
    for (0..@as(usize, @intCast(left_length))) |left| {
        var diagonal: i64 = 0;
        for (1..@as(usize, @intCast(right_length)) + 1) |right| {
            const above = dp[right];
            if (input_values[left_start + left] == input_values[right_start + right - 1]) {
                dp[right] = diagonal + 1;
            } else if (dp[right - 1] > dp[right]) {
                dp[right] = dp[right - 1];
            }
            diagonal = above;
        }
    }
    return dp[@intCast(right_length)];
}
