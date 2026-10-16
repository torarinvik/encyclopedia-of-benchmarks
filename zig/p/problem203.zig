fn isSquarefree(number: i64) bool {
    var copy = number;
    var divisor: i64 = 2;
    while (divisor * divisor <= copy) : (divisor += 1) {
        var multiplicity: usize = 0;
        while (@rem(copy, divisor) == 0) { copy = @divTrunc(copy, divisor); multiplicity += 1; }
        if (multiplicity >= 2) return false;
    }
    return true;
}

export fn problem203(depth: i64) i64 {
    if (depth > 51) return -1;
    var row = [_]i64{0} ** 51;
    var values = [_]i64{0} ** 1326;
    row[0] = 1;
    values[0] = 1;
    var count: usize = 1;
    var row_length: usize = 1;
    const rows: usize = if (depth < 1) 1 else @intCast(depth);
    for (2..(rows + 1)) |_| {
        row[row_length] = 1;
        var col = row_length - 1;
        while (col > 0) : (col -= 1) row[col] += row[col - 1];
        row[0] = 1;
        row_length += 1;
        for (0..row_length) |col_index| { values[count] = row[col_index]; count += 1; }
    }
    for (1..count) |i| {
        const value = values[i];
        var j = i;
        while (j > 0 and values[j - 1] > value) : (j -= 1) values[j] = values[j - 1];
        values[j] = value;
    }
    var total: i64 = 0;
    for (0..count) |i| {
        if (i > 0 and values[i] == values[i - 1]) continue;
        if (isSquarefree(values[i])) total += values[i];
    }
    return total;
}
