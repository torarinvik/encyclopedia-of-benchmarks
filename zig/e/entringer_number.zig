/// Return one entry of the Entringer triangle using its row recurrence.
pub export fn entringer_number(values: [*c]const i64, length: usize) i64 {
    if (values == null or length != 2) return -1;
    const n = values[0];
    const target = values[1];
    if (n < 0 or n > 12 or target < 0 or target > n) return -1;
    var previous: [13]i64 = @splat(0);
    var current: [13]i64 = @splat(0);
    previous[0] = 1;
    var row: i64 = 1;
    while (row <= n) : (row += 1) {
        current[0] = 0;
        var col: i64 = 1;
        while (col <= row) : (col += 1) {
            current[@intCast(col)] = current[@intCast(col - 1)] + previous[@intCast(row - col)];
        }
        for (0..13) |i| {
            previous[i] = current[i];
            current[i] = 0;
        }
    }
    return previous[@intCast(target)];
}
