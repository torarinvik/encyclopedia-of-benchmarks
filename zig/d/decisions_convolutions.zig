const MAX_DECISIONS: i64 = 64;
const MAX_CRITERIA: i64 = 16;
const MAX_VALUE: i64 = 100000;

export fn decisions_convolutions(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 3) return -1;
    const values = input.?;
    const method = values[0];
    const n_arg = values[1];
    const m_arg = values[2];
    if ((method != 0 and method != 1) or n_arg < 1 or n_arg > MAX_DECISIONS
        or m_arg < 1 or m_arg > MAX_CRITERIA) return -1;
    const n: usize = @intCast(n_arg);
    const m: usize = @intCast(m_arg);
    if (length != 3 + m + n * m) return -1;
    for (0..m) |j| {
        if (values[3 + j] < -MAX_VALUE or values[3 + j] > MAX_VALUE) return -1;
    }
    for (0..n * m) |i| {
        if (values[3 + m + i] < -MAX_VALUE or values[3 + m + i] > MAX_VALUE) return -1;
    }
    var best_score: i64 = 0;
    var best_index: usize = 0;
    for (0..n) |i| {
        var score: i64 = 0;
        for (0..m) |j| {
            const product = values[3 + m + i * m + j] * values[3 + j];
            if (method == 0) score += product else if (j == 0 or product < score) score = product;
        }
        if (i == 0 or score > best_score) { best_score = score; best_index = i; }
    }
    return @intCast(best_index);
}
