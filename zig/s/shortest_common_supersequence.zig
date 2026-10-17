export fn shortest_common_supersequence(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 130) return -1;
    const values = input.?;
    const m_value = values[0];
    const n_value = values[1];
    if (m_value < 0 or m_value > 64 or n_value < 0 or n_value > 64) return -1;
    const m: usize = @intCast(m_value);
    const n: usize = @intCast(n_value);
    if (length != 2 + m + n) return -1;
    for (2..length) |index| {
        if (values[index] < 32 or values[index] > 126) return -1;
    }

    var lcs: [65 * 65]i64 = @splat(0);
    for (1..m + 1) |i| {
        for (1..n + 1) |j| {
            const cell = i * 65 + j;
            if (values[1 + i] == values[1 + m + j]) {
                lcs[cell] = lcs[(i - 1) * 65 + j - 1] + 1;
            } else {
                const above = lcs[(i - 1) * 65 + j];
                const left = lcs[i * 65 + j - 1];
                lcs[cell] = if (above > left) above else left;
            }
        }
    }

    var reversed: [128]u8 = undefined;
    var used: usize = 0;
    var i = m;
    var j = n;
    while (i > 0 and j > 0) {
        if (values[1 + i] == values[1 + m + j]) {
            reversed[used] = @intCast(values[1 + i]);
            used += 1;
            i -= 1;
            j -= 1;
        } else if (lcs[(i - 1) * 65 + j] > lcs[i * 65 + j - 1]) {
            reversed[used] = @intCast(values[1 + i]);
            used += 1;
            i -= 1;
        } else {
            // The pinned implementations choose Y when the LCS values tie.
            reversed[used] = @intCast(values[1 + m + j]);
            used += 1;
            j -= 1;
        }
    }
    while (i > 0) {
        reversed[used] = @intCast(values[1 + i]);
        used += 1;
        i -= 1;
    }
    while (j > 0) {
        reversed[used] = @intCast(values[1 + m + j]);
        used += 1;
        j -= 1;
    }

    if (output == null or capacity < used) return -2;
    const destination = output.?;
    for (0..used) |index| destination[index] = reversed[used - 1 - index];
    return @intCast(used);
}
