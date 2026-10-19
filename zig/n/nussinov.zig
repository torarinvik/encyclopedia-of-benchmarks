const MAX_N: usize = 128;

export fn nussinov(values: [*]const i64, length: usize) i64 {
    if (length != 1) return -1;
    const n_value = values[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(n_value);
    var bases = [_]i64{0} ** MAX_N;
    var table = [_][MAX_N]i64{[_]i64{0} ** MAX_N} ** MAX_N;
    for (0..n) |i| bases[i] = @intCast((i + 1) % 4);

    var cursor = n;
    while (cursor > 0) {
        cursor -= 1;
        const i = cursor;
        var j = i + 1;
        while (j < n) : (j += 1) {
            var score = table[i][j - 1];
            if (i + 1 < n) {
                score = @max(score, table[i + 1][j]);
                var inside = table[i + 1][j - 1];
                if (i < j - 1 and bases[i] + bases[j] == 3) inside += 1;
                score = @max(score, inside);
            }
            var k = i + 1;
            while (k < j) : (k += 1) {
                score = @max(score, table[i][k] + table[k + 1][j]);
            }
            table[i][j] = score;
        }
    }

    var checksum: i64 = 0;
    for (0..n) |row| {
        for (row..n) |col| checksum += table[row][col];
    }
    return checksum;
}
