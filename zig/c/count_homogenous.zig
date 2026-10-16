/// Count contiguous runs of equal ASCII bytes.
export fn count_homogenous(input: [*]const i64, length: usize) i64 {
    if (length < 1 or input[0] < 0 or input[0] > 4096) return -1;
    const count: usize = @intCast(input[0]);
    if (length != count + 1) return -1;
    for (0..count) |i| {
        if (input[1 + i] < 0 or input[1 + i] > 127) return -1;
    }
    if (count == 0) return 0;
    var runs: usize = 1;
    for (2..count + 1) |i| {
        if (input[i] != input[i - 1]) runs += 1;
    }
    return @intCast(runs);
}
