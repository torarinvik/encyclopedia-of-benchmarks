const MAX_N: usize = 8;
const INVALID_RESULT: i64 = -9_223_372_036_854_775_808;

export fn rsk_row_insertion(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_N + 2) return INVALID_RESULT;
    const n_value = input[0];
    if (n_value < 0 or n_value > @as(i64, @intCast(MAX_N))
        or length != @as(usize, @intCast(n_value)) + 1) return INVALID_RESULT;
    const n: usize = @intCast(n_value);

    var seen = [_]bool{false} ** MAX_N;
    for (0..n) |i| {
        const value = input[i + 1];
        if (value < 0 or value >= n_value or seen[@intCast(value)]) return INVALID_RESULT;
        seen[@intCast(value)] = true;
    }
    if (n == 0) return 0;

    var p = [_]i64{0} ** (MAX_N * MAX_N);
    var q = [_]i64{0} ** (MAX_N * MAX_N);
    var row_lengths = [_]usize{0} ** MAX_N;
    var row_count: usize = 0;
    for (1..n + 1) |step| {
        var value = input[step] + 1;
        var row: usize = 0;
        while (true) {
            if (row == row_count) {
                p[row * MAX_N] = value;
                q[row * MAX_N] = @intCast(step);
                row_lengths[row] = 1;
                row_count += 1;
                break;
            }
            var column: usize = 0;
            while (column < row_lengths[row] and p[row * MAX_N + column] < value) : (column += 1) {}
            if (column == row_lengths[row]) {
                p[row * MAX_N + column] = value;
                q[row * MAX_N + column] = @intCast(step);
                row_lengths[row] += 1;
                break;
            }
            const bumped = p[row * MAX_N + column];
            p[row * MAX_N + column] = value;
            value = bumped;
            row += 1;
        }
    }

    var p_row = [_]i64{0} ** MAX_N;
    var q_row = [_]i64{0} ** MAX_N;
    for (0..row_count) |row| {
        for (0..row_lengths[row]) |column| {
            p_row[@intCast(p[row * MAX_N + column] - 1)] = @intCast(row);
            q_row[@intCast(q[row * MAX_N + column] - 1)] = @intCast(row);
        }
    }
    var code: i64 = n_value;
    for (0..n) |label| {
        code = code * 9 + p_row[label] + 1;
        code = code * 9 + q_row[label] + 1;
    }
    return code;
}
