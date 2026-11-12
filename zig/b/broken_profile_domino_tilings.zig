const MaxStates: usize = 256;
const Modulus: i64 = 998_244_353;

export fn broken_profile_domino_tilings(input: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const h0 = input[0]; const w0 = input[1];
    if (h0 < 1 or h0 > 64 or w0 < 1 or w0 > 64 or @min(h0, w0) > 8 or h0 * w0 > 512) return -1;
    const height: usize = @intCast(@max(h0, w0));
    const width: usize = @intCast(@min(h0, w0));
    const states = @as(usize, 1) << @intCast(width);
    const full = states - 1;
    var dp: [MaxStates]i64 = @splat(0);
    var next: [MaxStates]i64 = @splat(0);
    dp[0] = 1;
    for (0..height) |row| {
        @memset(&next, 0);
        for (0..states) |incoming| {
            if (dp[incoming] == 0) continue;
            for (0..states) |outgoing| {
                if ((incoming & outgoing) != 0 or (row + 1 == height and outgoing != 0)) continue;
                const free = full & ~(incoming | outgoing);
                var col: usize = 0;
                var valid = true;
                while (col < width) {
                    if ((free & (@as(usize, 1) << @intCast(col))) != 0) {
                        if (col + 1 >= width or (free & (@as(usize, 1) << @intCast(col + 1))) == 0) { valid = false; break; }
                        col += 2;
                    } else { col += 1; }
                }
                if (valid) next[outgoing] = @mod(next[outgoing] + dp[incoming], Modulus);
            }
        }
        dp = next;
    }
    return dp[0];
}
