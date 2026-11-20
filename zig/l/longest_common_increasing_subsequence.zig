export fn longest_common_increasing_subsequence(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 67) return -1;
    const input = input_opt.?[0..length];
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 0 or n_value > 32 or m_value < 0 or m_value > 32) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + n + m) return -1;
    for (input[2..]) |value| {
        if (value < -16 or value > 16) return -1;
    }

    var ending_at: [32]i64 = @splat(0);
    for (0..n) |i| {
        const value = input[2 + i];
        var best_smaller: i64 = 0;
        for (0..m) |j| {
            const other = input[2 + n + j];
            if (value > other) {
                best_smaller = @max(best_smaller, ending_at[j]);
            } else if (value == other) {
                ending_at[j] = @max(ending_at[j], best_smaller + 1);
            }
        }
    }
    var answer: i64 = 0;
    for (0..m) |j| answer = @max(answer, ending_at[j]);
    return answer;
}
