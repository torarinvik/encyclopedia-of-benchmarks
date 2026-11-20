const CodeStates: usize = 6561;
const MaxStates: usize = 78732;

fn cellColor(code: i64) i64 {
    if (code == 0) return -1;
    return if (code <= 4) 0 else 1;
}

fn advanceFrontier(inputCodes: [4]i64, closed: i64, diagonal: i64, color: i64,
    row: usize, column: usize, outputCodes: *[4]i64,
    outputClosed: *i64, outputDiagonal: *i64) bool {
    if ((closed & (@as(i64, 1) << @intCast(color))) != 0) return false;
    const above = inputCodes[column];
    const left: i64 = if (column == 0) 0 else inputCodes[column - 1];
    if (row != 0 and column != 0 and cellColor(above) == color and
        cellColor(left) == color and diagonal == color + 1) return false;

    outputCodes.* = inputCodes;
    outputCodes.*[column] = 0;
    const aboveColor = cellColor(above);
    const aboveLabel: i64 = if (aboveColor == color) (if (color == 0) above else above - 4) else 0;
    const leftLabel: i64 = if (cellColor(left) == color) (if (color == 0) left else left - 4) else 0;
    var chosenLabel: i64 = if (aboveLabel != 0) aboveLabel else leftLabel;
    if (aboveLabel != 0 and leftLabel != 0 and aboveLabel != leftLabel) {
        for (0..4) |slot| {
            if (color == 0 and outputCodes.*[slot] == leftLabel) outputCodes.*[slot] = aboveLabel;
            if (color == 1 and outputCodes.*[slot] == 4 + leftLabel) outputCodes.*[slot] = 4 + aboveLabel;
        }
        chosenLabel = aboveLabel;
    }
    if (chosenLabel == 0) {
        var maximum: i64 = 0;
        for (0..4) |slot| {
            const code = outputCodes.*[slot];
            if (cellColor(code) == color) {
                const label = if (color == 0) code else code - 4;
                if (label > maximum) maximum = label;
            }
        }
        chosenLabel = maximum + 1;
    }
    outputCodes.*[column] = if (color == 0) chosenLabel else 4 + chosenLabel;

    outputClosed.* = closed;
    if (above != 0 and aboveColor != color) {
        var oldStillPresent = false;
        var otherSameColor = false;
        for (0..4) |slot| {
            const code = outputCodes.*[slot];
            if (code == above) oldStillPresent = true;
            if (cellColor(code) == aboveColor and code != above) otherSameColor = true;
        }
        if (!oldStillPresent) {
            if (otherSameColor) return false;
            outputClosed.* = closed | (@as(i64, 1) << @intCast(aboveColor));
        }
    }

    var mapping: [9]i64 = @splat(0);
    var nextBlack: i64 = 0;
    var nextWhite: i64 = 0;
    for (0..4) |slot| {
        const code = outputCodes.*[slot];
        if (code == 0) continue;
        if (code <= 4) {
            const key: usize = @intCast(code);
            if (mapping[key] == 0) { nextBlack += 1; mapping[key] = nextBlack; }
            outputCodes.*[slot] = mapping[key];
        } else {
            const key: usize = @intCast(code);
            if (mapping[key] == 0) { nextWhite += 1; mapping[key] = 4 + nextWhite; }
            outputCodes.*[slot] = mapping[key];
        }
    }
    outputDiagonal.* = if (aboveColor < 0) 0 else aboveColor + 1;
    return true;
}

fn encodeState(codes: [4]i64, closed: i64, diagonal: i64) usize {
    const powers = [_]usize{ 1, 9, 81, 729 };
    var codeKey: usize = 0;
    for (0..4) |slot| codeKey += @as(usize, @intCast(codes[slot])) * powers[slot];
    return (@as(usize, @intCast(closed)) * 3 + @as(usize, @intCast(diagonal))) * CodeStates + codeKey;
}

export fn connectivity_aware_plug_dp_binary_grid_colorings(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length != 2) return -1;
    const input = input_opt.?;
    const rowsValue = input[0];
    const columnsValue = input[1];
    if (rowsValue < 2 or rowsValue > 4 or columnsValue < 2 or columnsValue > 4) return -1;
    const rows: usize = @intCast(rowsValue);
    const columns: usize = @intCast(columnsValue);

    var dp: [MaxStates]i64 = @splat(0);
    var next: [MaxStates]i64 = @splat(0);
    dp[0] = 1;
    for (0..rows * columns) |cell| {
        const row = cell / columns;
        const column = cell % columns;
        @memset(&next, 0);
        for (0..MaxStates) |state| {
            if (dp[state] == 0) continue;
            var codeKey = state % CodeStates;
            const flags = state / CodeStates;
            const diagonal: i64 = @intCast(flags % 3);
            const closed: i64 = @intCast(flags / 3);
            var codes: [4]i64 = @splat(0);
            for (0..4) |slot| {
                codes[slot] = @intCast(codeKey % 9);
                codeKey /= 9;
            }
            for (0..2) |rawColor| {
                const color: i64 = @intCast(rawColor);
                var outputCodes: [4]i64 = @splat(0);
                var outputClosed: i64 = 0;
                var outputDiagonal: i64 = 0;
                if (advanceFrontier(codes, closed, diagonal, color, row, column,
                    &outputCodes, &outputClosed, &outputDiagonal)) {
                    const destination = encodeState(outputCodes, outputClosed, outputDiagonal);
                    next[destination] += dp[state];
                }
            }
        }
        dp = next;
    }

    var total: i64 = 0;
    for (0..MaxStates) |state| {
        if (dp[state] == 0) continue;
        var codeKey = state % CodeStates;
        const closed: i64 = @intCast((state / CodeStates) / 3);
        var seenBlack: [5]bool = @splat(false);
        var seenWhite: [5]bool = @splat(false);
        var blackComponents: i64 = 0;
        var whiteComponents: i64 = 0;
        for (0..4) |_| {
            const code = codeKey % 9;
            codeKey /= 9;
            if (code >= 1 and code <= 4 and !seenBlack[code]) {
                seenBlack[code] = true;
                blackComponents += 1;
            } else if (code >= 5 and code <= 8 and !seenWhite[code - 4]) {
                seenWhite[code - 4] = true;
                whiteComponents += 1;
            }
        }
        if (((closed & 1) != 0 and blackComponents == 0 or
            (closed & 1) == 0 and blackComponents == 1) and
            ((closed & 2) != 0 and whiteComponents == 0 or
            (closed & 2) == 0 and whiteComponents == 1)) total += dp[state];
    }
    return total;
}
