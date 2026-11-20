const MAX_INDEX: i64 = 128;

export fn hofstadter_q_sequence(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > 2) return -1;
    const input = input_opt.?[0..length];
    if (length != 1 or input[0] < 1 or input[0] > MAX_INDEX) return -1;

    const target: usize = @intCast(input[0]);
    var q = [_]i64{0} ** 129;
    q[1] = 1;
    if (target >= 2) q[2] = 1;
    var n: usize = 3;
    while (n <= target) : (n += 1) {
        const left = @as(i64, @intCast(n)) - q[n - 1];
        const right = @as(i64, @intCast(n)) - q[n - 2];
        if (left < 1 or right < 1 or left >= @as(i64, @intCast(n))
                or right >= @as(i64, @intCast(n))) return -1;
        q[n] = q[@intCast(left)] + q[@intCast(right)];
    }
    return q[target];
}
