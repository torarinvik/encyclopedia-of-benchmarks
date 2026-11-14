fn next(input: [*]const i64, node: i64) i64 {
    return input[2 + @as(usize, @intCast(node))];
}

export fn functional_graph_cycle_brent(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > 67) return -1;
    const input = input_opt.?;
    const n = input[0];
    const start = input[1];
    if (n < 1 or n > 64 or start < 0 or start >= n or length != @as(usize, @intCast(n+2))) return -1;
    for (0..@as(usize, @intCast(n))) |i| {
        if (input[2+i] < 0 or input[2+i] >= n) return -1;
    }
    var checkpoint = start;
    var moving = next(input, start);
    var power: i64 = 1;
    var period: i64 = 1;
    while (checkpoint != moving) {
        if (power == period) { checkpoint = moving; power *= 2; period = 0; }
        moving = next(input, moving); period += 1;
    }
    var left = start;
    var right = start;
    for (0..@as(usize, @intCast(period))) |_| right = next(input, right);
    var tail: i64 = 0;
    while (left != right) { left = next(input, left); right = next(input, right); tail += 1; }
    return 65 * tail + period;
}
