const MAX_INDEX: i64 = 8192;

export fn hofstadter_conway_10000_sequence(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > 2) return -1;
    const input = input_opt.?[0..length];
    if (length != 1 or input[0] < 2 or input[0] > MAX_INDEX) return -1;

    const target: usize = @intCast(input[0]);
    var a = [_]i64{0} ** 8193;
    a[1] = 1;
    a[2] = 1;
    var n: usize = 3;
    while (n <= target) : (n += 1) {
        const previous = a[n - 1];
        const other = @as(i64, @intCast(n)) - previous;
        if (previous < 1 or previous >= @as(i64, @intCast(n))
                or other < 1 or other >= @as(i64, @intCast(n))) return -1;
        a[n] = a[@intCast(previous)] + a[@intCast(other)];
    }
    return a[target];
}
