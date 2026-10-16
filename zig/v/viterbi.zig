export fn viterbi(input: [*]const i64, length: usize, output: [*]u8, capacity: usize) i64 {
    if (length == 0 or length > 64) return -1;
    for (0..length) |i| if (input[i] < 0 or input[i] > 2) return -1;
    if (capacity < length * 8) return -2;
    const tr = [4]f64{0.7, 0.3, 0.4, 0.6};
    const em = [6]f64{0.5, 0.4, 0.1, 0.1, 0.3, 0.6};
    var score = [2]f64{0.6 * em[@intCast(input[0])], 0.4 * em[3 + @as(usize, @intCast(input[0]))]};
    var back: [64][2]usize = undefined;
    for (1..length) |t| {
        var next = [2]f64{0,0};
        for (0..2) |s| {
            const obs: usize = @intCast(input[t]);
            const a = score[0] * tr[s] * em[s*3+obs];
            const b = score[1] * tr[2+s] * em[s*3+obs];
            const prior: usize = if (b > a) 1 else 0;
            back[t][s] = prior;
            next[s] = if (prior == 0) a else b;
        }
        score = next;
    }
    var state: usize = if (score[1] > score[0]) 1 else 0;
    var path: [64]i64 = undefined;
    path[length-1] = @intCast(state);
    var t = length;
    while (t > 1) { t -= 1; state = back[t][state]; path[t-1] = @intCast(state); }
    for (0..length) |i| {
        const bits: u64 = @bitCast(path[i]);
        for (0..8) |b| output[i*8+b] = @truncate(bits >> @intCast(b*8));
    }
    return @intCast(length*8);
}
