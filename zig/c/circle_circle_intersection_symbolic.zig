// Independently authored draft; not compiled or run.
export fn circle_circle_intersection_symbolic(v: [*c]const i64, n: usize,
    out: [*c]u8, cap: usize) i64 {
    if (v == null or n != 6) return -1;
    for (0..6) |i| {
        if (v[i] < -1000 or v[i] > 1000) return -1;
    }
    if (v[2] < 1 or v[5] < 1) return -1;
    const dx=v[3]-v[0]; const dy=v[4]-v[1]; const d=dx*dx+dy*dy;
    var words: [7]i64 = @splat(0); var count: usize = 1;
    if (d == 0) {
        words[0]=if (v[2] == v[5]) 3 else 0;
    } else {
        const t=d+v[2]*v[2]-v[5]*v[5]; const h=4*v[2]*v[2]*d-t*t;
        if (h >= 0) {
            const den=2*d; count=7;
            words=.{if (h == 0) 1 else 2,den*v[0]+dx*t,den*v[1]+dy*t,den,-dy,dx,h};
        }
    }
    const needed=8*count;
    if (out == null or cap < needed) return -2;
    for (0..count) |i| {
        const bits: u64 = @bitCast(words[i]);
        for (0..8) |j| out[8*i+j]=@truncate(bits >> @as(u6,@intCast(8*j)));
    }
    return @intCast(needed);
}
