const MAX_LENGTH: usize = 256;
export fn longest_common_substring(raw: [*]const i64, length: usize) i64 {
    if (length < 2) return -1;
    const input = raw[0..length];
    if (input[0] < 0 or input[0] > MAX_LENGTH) return -1;
    const first_length: usize = @intCast(input[0]);
    if (first_length + 2 > length or input[first_length + 1] < 0 or input[first_length + 1] > MAX_LENGTH) return -1;
    const second_length: usize = @intCast(input[first_length + 1]);
    if (length != first_length + second_length + 2) return -1;
    const first = input[1..][0..first_length];
    const second = input[first_length + 2 ..];
    for (first) |value| { if (value < 32 or value > 126) return -1; }
    for (second) |value| { if (value < 32 or value > 126) return -1; }
    var dp: [MAX_LENGTH + 1]i64 = @splat(0);
    var best: i64 = 0;
    for (1..first_length + 1) |i| {
        var j = second_length;
        while (j > 0) : (j -= 1) {
            if (first[i - 1] == second[j - 1]) { dp[j] = dp[j - 1] + 1; best = @max(best, dp[j]); }
            else { dp[j] = 0; }
        }
    }
    return best;
}
