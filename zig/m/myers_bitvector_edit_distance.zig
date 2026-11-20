// Uncompiled multiword bit-vector global edit-distance draft.
export fn myers_bitvector_edit_distance(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 515) return -1;
    const nr = input[0]; const mr = input[1];
    if (nr < 0 or nr > 256 or mr < 0 or mr > 256 or length != @as(usize,@intCast(2+nr+mr))) return -1;
    const n: usize = @intCast(nr); const m: usize = @intCast(mr);
    for (2..length) |i| if (input[i] < 0 or input[i] > 255) { return -1; };
    if (n == 0) return mr;
    var masks = [_][4]u64{[_]u64{0} ** 4} ** 256;
    var pv = [_]u64{~@as(u64,0)} ** 4;
    var mv = [_]u64{0} ** 4;
    const words = (n+63)/64;
    for (0..n) |i| {
        const symbol: usize = @intCast(input[2+i]);
        masks[symbol][i/64] |= @as(u64,1) << @intCast(i%64);
    }
    var score = nr;
    const top = @as(u64,1) << @as(u6,@intCast((n-1)%64));
    for (0..m) |i| {
        const symbol: usize = @intCast(input[2+n+i]);
        var add: u64 = 0; var pc: u64 = 1; var mc: u64 = 0;
        for (0..words) |j| {
            const eq = masks[symbol][j]; const p = pv[j]; const v = mv[j];
            const term = eq & p;
            const first = term +% p;
            const sum = first +% add;
            add = if (first < term or sum < first) 1 else 0;
            const xh = (sum ^ p) | eq; const xv = eq | v;
            var ph = v | ~(xh | p); var mh = p & xh;
            if (j == words-1) {
                if (ph & top != 0) score += 1;
                if (mh & top != 0) score -= 1;
            }
            const next_pc = ph >> 63; const next_mc = mh >> 63;
            ph = (ph << 1) | pc; mh = (mh << 1) | mc;
            pc = next_pc; mc = next_mc;
            pv[j] = mh | ~(xv | ph); mv[j] = ph & xv;
        }
    }
    return score;
}
