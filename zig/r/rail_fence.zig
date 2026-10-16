fn railForPosition(position: usize, rails: usize) usize {
    const period = 2 * (rails - 1);
    const phase = position % period;
    return if (phase < rails) phase else period - phase;
}

export fn rail_fence(input: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > 260) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 1 or values[1] < 2 or values[1] > 8) return -1;
    if (values[2] < 0 or values[2] > 256) return -1;
    const mode: usize = @intCast(values[0]);
    const rails: usize = @intCast(values[1]);
    const n: usize = @intCast(values[2]);
    if (length != n + 3) return -1;
    for (values[3..]) |byte| {
        if (byte < 0 or byte > 127) return -1;
    }
    if (output == null or output_capacity < n) return -2;
    const result = output.?[0..n];

    if (mode == 0) {
        var out: usize = 0;
        for (0..rails) |rail| {
            for (0..n) |position| {
                if (railForPosition(position, rails) == rail) {
                    result[out] = @intCast(values[position + 3]);
                    out += 1;
                }
            }
        }
    } else {
        var counts = [_]usize{0} ** 8;
        var starts = [_]usize{0} ** 8;
        var used = [_]usize{0} ** 8;
        for (0..n) |position| counts[railForPosition(position, rails)] += 1;
        for (1..rails) |rail| starts[rail] = starts[rail - 1] + counts[rail - 1];
        for (0..n) |position| {
            const rail = railForPosition(position, rails);
            result[position] = @intCast(values[3 + starts[rail] + used[rail]]);
            used[rail] += 1;
        }
    }
    return @intCast(n);
}
