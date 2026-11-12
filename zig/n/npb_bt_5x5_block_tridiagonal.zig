const BLOCK: usize = 5;
const MAX_LINE: usize = 4;
const ROW_WORDS: usize = 80;
const INVALID_RESULT: f64 = -1.0e300;

fn solveBlock(matrix: *const [BLOCK][BLOCK]f64, right: *const [BLOCK][6]f64) ?[BLOCK][6]f64 {
    var work: [BLOCK][11]f64 = undefined;
    for (0..BLOCK) |r| {
        for (0..BLOCK) |c| work[r][c] = matrix[r][c];
        for (0..6) |c| work[r][BLOCK + c] = right[r][c];
    }
    for (0..BLOCK) |pivot| {
        var best = pivot;
        var r = pivot + 1;
        while (r < BLOCK) : (r += 1) {
            if (@abs(work[r][pivot]) > @abs(work[best][pivot])) best = r;
        }
        if (work[best][pivot] == 0.0) return null;
        const saved = work[pivot];
        work[pivot] = work[best];
        work[best] = saved;
        const divisor = work[pivot][pivot];
        var c = pivot;
        while (c < 11) : (c += 1) work[pivot][c] /= divisor;
        for (0..BLOCK) |row| {
            if (row == pivot) continue;
            const factor = work[row][pivot];
            c = pivot;
            while (c < 11) : (c += 1) work[row][c] -= factor * work[pivot][c];
        }
    }
    var answer: [BLOCK][6]f64 = undefined;
    for (0..BLOCK) |r| for (0..6) |c| { answer[r][c] = work[r][BLOCK + c]; };
    return answer;
}

export fn npb_bt_5x5_block_tridiagonal(input: ?[*]const i64, length: usize) f64 {
    const values = input orelse return INVALID_RESULT;
    if (length < 1 or length > 1 + ROW_WORDS * MAX_LINE) return INVALID_RESULT;
    if (values[0] < 2 or values[0] > MAX_LINE) return INVALID_RESULT;
    const n: usize = @intCast(values[0]);
    if (length != 1 + ROW_WORDS * n) return INVALID_RESULT;

    var lower: [MAX_LINE][BLOCK][BLOCK]f64 = undefined;
    var diagonal: [MAX_LINE][BLOCK][BLOCK]f64 = undefined;
    var upper: [MAX_LINE][BLOCK][BLOCK]f64 = undefined;
    var rhs: [MAX_LINE][BLOCK]f64 = undefined;
    for (0..n) |row| {
        var cursor = 1 + ROW_WORDS * row;
        for (0..3) |which| {
            for (0..BLOCK) |r| for (0..BLOCK) |c| {
                const value = values[cursor];
                cursor += 1;
                if (which == 1) {
                    if (r == c) {
                        if (value < 40 or value > 64) return INVALID_RESULT;
                    } else if (value < -2 or value > 2) return INVALID_RESULT;
                    diagonal[row][r][c] = @floatFromInt(value);
                } else {
                    if (value < -2 or value > 2) return INVALID_RESULT;
                    if (which == 0) lower[row][r][c] = @floatFromInt(value) else upper[row][r][c] = @floatFromInt(value);
                }
            };
        }
        for (0..BLOCK) |r| {
            const value = values[cursor];
            cursor += 1;
            if (value < -1000 or value > 1000) return INVALID_RESULT;
            rhs[row][r] = @floatFromInt(value);
        }
        for (0..BLOCK) |r| for (0..BLOCK) |c| {
            if (row == 0 and lower[row][r][c] != 0.0) return INVALID_RESULT;
            if (row + 1 == n and upper[row][r][c] != 0.0) return INVALID_RESULT;
        };
        for (0..BLOCK) |r| {
            var off_diagonal: f64 = 0.0;
            for (0..BLOCK) |c| {
                if (r != c) off_diagonal += @abs(diagonal[row][r][c]);
                off_diagonal += @abs(lower[row][r][c]) + @abs(upper[row][r][c]);
            }
            if (diagonal[row][r][r] <= off_diagonal) return INVALID_RESULT;
        }
    }

    var modified_upper: [MAX_LINE][BLOCK][BLOCK]f64 = undefined;
    var modified_rhs: [MAX_LINE][BLOCK]f64 = undefined;
    for (0..n) |row| {
        var schur: [BLOCK][BLOCK]f64 = undefined;
        var reduced: [BLOCK]f64 = undefined;
        var right: [BLOCK][6]f64 = undefined;
        for (0..BLOCK) |r| {
            reduced[r] = rhs[row][r];
            for (0..BLOCK) |c| {
                schur[r][c] = diagonal[row][r][c];
                if (row > 0) for (0..BLOCK) |k| {
                    schur[r][c] -= lower[row][r][k] * modified_upper[row - 1][k][c];
                };
            }
            if (row > 0) for (0..BLOCK) |k| { reduced[r] -= lower[row][r][k] * modified_rhs[row - 1][k]; };
            for (0..BLOCK) |c| right[r][c] = upper[row][r][c];
            right[r][5] = reduced[r];
        }
        const solved = solveBlock(&schur, &right) orelse return INVALID_RESULT;
        for (0..BLOCK) |r| {
            modified_rhs[row][r] = solved[r][5];
            for (0..BLOCK) |c| modified_upper[row][r][c] = solved[r][c];
        }
    }
    var solution: [MAX_LINE][BLOCK]f64 = undefined;
    for (0..BLOCK) |r| solution[n - 1][r] = modified_rhs[n - 1][r];
    var row = n - 1;
    while (row > 0) {
        row -= 1;
        for (0..BLOCK) |r| {
            solution[row][r] = modified_rhs[row][r];
            for (0..BLOCK) |c| solution[row][r] -= modified_upper[row][r][c] * solution[row + 1][c];
        }
    }
    var checksum: f64 = 0.0;
    for (0..n) |block_row| for (0..BLOCK) |r| {
        checksum += @as(f64, @floatFromInt(block_row * BLOCK + r + 1)) * solution[block_row][r];
    };
    return checksum;
}
