/// Count values through limit with exactly ten valid arithmetic-progression solutions.
const MAX_LIMIT: i64 = 1_000_000;

export fn problem135(limit: i64) i64 {
    if (limit > MAX_LIMIT) return -1;
    if (limit < 0) return 0;
    var frequency: [1_000_001]u8 = @splat(0);
    var first_term: i64 = 1;
    while (first_term <= limit) : (first_term += 1) {
        var n = first_term;
        while (n <= limit) : (n += first_term) {
            var common_difference = first_term + @divTrunc(n, first_term);
            if (@mod(common_difference, 4) == 0) {
                common_difference = @divTrunc(common_difference, 4);
                if (first_term > common_difference and first_term < 4 * common_difference) {
                    const index: usize = @intCast(n);
                    if (frequency[index] < 11) frequency[index] += 1;
                }
            }
        }
    }
    var count: i64 = 0;
    var n: i64 = 1;
    while (n <= limit) : (n += 1) {
        if (frequency[@intCast(n)] == 10) count += 1;
    }
    return count;
}
