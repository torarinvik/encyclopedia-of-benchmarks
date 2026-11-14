pub export fn reservoir_sampling_algorithm_r(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 130 or input[0] < 0 or input[0] > 64 or input[1] < 0 or input[1] > input[0]) return -1;
    const n: usize = @intCast(input[0]);
    const k: usize = @intCast(input[1]);
    if (length != 2+2*n-k) return -1;
    for (0..n) |i| { if (input[2+i] < -1000000 or input[2+i] > 1000000) return -1; }
    for (k..n) |i| { if (input[2+n+i-k] < 0 or input[2+n+i-k] > @as(i64, @intCast(i))) return -1; }
    if (output == null or capacity < 8*k) return -2;
    var reservoir: [64]i64 = @splat(0);
    for (0..k) |i| reservoir[i] = input[2+i];
    for (k..n) |i| {
        const draw: usize = @intCast(input[2+n+i-k]);
        if (draw < k) reservoir[draw] = input[2+i];
    }
    for (0..k) |i| {
        var encoded: u64 = @bitCast(reservoir[i]);
        for (0..8) |j| { output[8*i+j] = @truncate(encoded); encoded >>= 8; }
    }
    return @intCast(8*k);
}
