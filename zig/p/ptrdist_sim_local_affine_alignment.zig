// Clean-room port of SIM's documented first-best local affine score.
export fn ptrdist_sim_local_affine_alignment(input: ?[*]const i64, length: usize) callconv(.c) i64 {
    const stride: usize = 65;
    if (input == null or length < 4 or length > 130) return -1;
    const values = input.?;
    if (values[0] < 1 or values[0] > 64) return -1;
    const left: usize = @intCast(values[0]);
    const right_pos = 1 + left;
    if (right_pos >= length or values[right_pos] < 1 or values[right_pos] > 64) return -1;
    const right: usize = @intCast(values[right_pos]);
    if (length != right_pos + 1 + right) return -1;
    for (0..left) |i| { const c = values[1+i]; if (c != 65 and c != 67 and c != 71 and c != 84) return -1; }
    for (0..right) |j| { const c = values[right_pos+1+j]; if (c != 65 and c != 67 and c != 71 and c != 84) return -1; }
    var h: [stride * stride]i64 = [_]i64{0} ** (stride * stride);
    var d: [stride * stride]i64 = [_]i64{0} ** (stride * stride);
    var f: [stride * stride]i64 = [_]i64{0} ** (stride * stride);
    for (1..right+1) |j| d[j] = -60;
    for (1..left+1) |i| f[i*stride] = -60;
    var best: i64 = 0;
    for (1..left+1) |i| for (1..right+1) |j| {
        const p = i*stride+j;
        d[p] = @max(h[p-stride]-62, d[p-stride]-2);
        f[p] = @max(h[p-1]-62, f[p-1]-2);
        var score = h[p-stride-1] + (if (values[i] == values[right_pos+j]) @as(i64, 10) else -10);
        score = @max(0, @max(score, @max(d[p], f[p])));
        h[p] = score;
        best = @max(best, score);
    };
    return best;
}
