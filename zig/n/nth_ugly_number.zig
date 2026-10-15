/// Return the zero-based 5-smooth number at index n.
export fn nth_ugly_number(n: i64) i64 {
    if (n < 0 or n > 12690) return -1;
    var values: [12691]i64 = [_]i64{0} ** 12691;
    values[0] = 1;
    var i2: usize = 0;
    var i3: usize = 0;
    var i5: usize = 0;
    var index: usize = 1;
    const target: usize = @intCast(n);
    while (index <= target) : (index += 1) {
        const c2 = 2 * values[i2];
        const c3 = 3 * values[i3];
        const c5 = 5 * values[i5];
        const next = @min(c2, @min(c3, c5));
        values[index] = next;
        if (c2 == next) i2 += 1;
        if (c3 == next) i3 += 1;
        if (c5 == next) i5 += 1;
    }
    return values[target];
}
