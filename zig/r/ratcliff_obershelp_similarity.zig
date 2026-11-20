const MAX_TEXT: usize = 32;

fn longestMatch(input: []const i64, firstBase: usize, secondBase: usize,
                a0: usize, a1: usize, b0: usize, b1: usize) i64 {
    var dp: [33]i64 = @splat(0);
    var bestLength: usize = 0;
    var bestA: usize = 0;
    var bestB: usize = 0;
    var i = a0;
    while (i < a1) : (i += 1) {
        var diagonal: i64 = 0;
        var column: usize = 1;
        while (column <= b1 - b0) : (column += 1) {
            const old = dp[column];
            const j = b0 + column - 1;
            if (input[firstBase + i] == input[secondBase + j]) {
                const current: usize = @intCast(diagonal + 1);
                dp[column] = @intCast(current);
                if (current > bestLength) {
                    bestLength = current;
                    bestA = i + 1 - current;
                    bestB = j + 1 - current;
                }
            } else dp[column] = 0;
            diagonal = old;
        }
    }
    return @intCast(bestLength * 4096 + bestA * 64 + bestB);
}

fn matchedCharacters(input: []const i64, firstBase: usize, secondBase: usize,
                     a0: usize, a1: usize, b0: usize, b1: usize) i64 {
    if (a0 >= a1 or b0 >= b1) return 0;
    const packed: usize = @intCast(longestMatch(input, firstBase, secondBase, a0, a1, b0, b1));
    const block = packed / 4096;
    if (block == 0) return 0;
    const rest = packed % 4096;
    const a = rest / 64;
    const b = rest % 64;
    return @as(i64, @intCast(block))
        + matchedCharacters(input, firstBase, secondBase, a0, a, b0, b)
        + matchedCharacters(input, firstBase, secondBase,
                            a + block, a1, b + block, b1);
}

export fn ratcliff_obershelp_similarity(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 67) return -1;
    const input = input_opt.?[0..length];
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_TEXT))
        or input[1] < 0 or input[1] > @as(i64, @intCast(MAX_TEXT))) return -1;
    const firstLength: usize = @intCast(input[0]);
    const secondLength: usize = @intCast(input[1]);
    if (length != 2 + firstLength + secondLength) return -1;
    for (input[2..]) |byte| {
        if (byte < 1 or byte > 127) return -1;
    }
    if (firstLength == 0 or secondLength == 0) return 0;
    const common = matchedCharacters(input, 2, 2 + firstLength,
                                     0, firstLength, 0, secondLength);
    return (200 * common) / @as(i64, @intCast(firstLength + secondLength));
}
