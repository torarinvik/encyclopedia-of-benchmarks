/// Return the exact Bell number for indices that fit in signed 64-bit output.
export fn bell_numbers(n: i64) i64 {
    if (n < 0 or n > 25) return -1;
    if (n == 0) return 1;

    var row: [26]i64 = @splat(0);
    row[0] = 1;
    const limit: usize = @intCast(n);
    for (1..limit) |current| {
        const previous_first = row[0];
        const previous_last = row[current - 1];
        row[0] = previous_last;
        var previous_old = previous_first;
        for (1..current + 1) |column| {
            const old_value: i64 = if (column < current) row[column] else 0;
            row[column] = row[column - 1] + previous_old;
            previous_old = old_value;
        }
    }
    return row[limit - 1];
}
