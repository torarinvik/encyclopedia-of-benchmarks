/// Return the LCS length using descending matching positions and an LIS frontier.
export fn hunt_szymanski_lcs(input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 131) return -1;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 0 or n_value > 64 or m_value < 0 or m_value > 64) return -1;
    if (length != 2 + @as(usize, @intCast(n_value)) + @as(usize, @intCast(m_value))) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    for (0..n + m) |i| {
        if (input[2 + i] < 0 or input[2 + i] > 127) return -1;
    }

    var right_positions: [8192]i32 = undefined;
    var position_count: [128]i32 = @splat(0);
    var tails: [64]i32 = undefined;
    for (0..m) |j| {
        const symbol: usize = @intCast(input[2 + n + j]);
        const count: usize = @intCast(position_count[symbol]);
        right_positions[symbol * 64 + count] = @intCast(j);
        position_count[symbol] += 1;
    }

    var tail_count: usize = 0;
    for (0..n) |i| {
        const symbol: usize = @intCast(input[2 + i]);
        var count: usize = @intCast(position_count[symbol]);
        while (count > 0) {
            count -= 1;
            const position = right_positions[symbol * 64 + count];
            var low: usize = 0;
            var high = tail_count;
            while (low < high) {
                const middle = low + (high - low) / 2;
                if (tails[middle] >= position) high = middle else low = middle + 1;
            }
            if (low == tail_count) {
                tails[tail_count] = position;
                tail_count += 1;
            } else {
                tails[low] = position;
            }
        }
    }
    return @intCast(tail_count);
}
