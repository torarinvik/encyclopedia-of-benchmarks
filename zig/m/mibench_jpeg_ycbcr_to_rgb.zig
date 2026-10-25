fn arshift16(x: i64) i64 { return if (x >= 0) @divTrunc(x, 65536) else -@divTrunc(-x + 65535, 65536); }
fn clamp8(x: i64) u8 { return @intCast(@min(255, @max(0, x))); }

export fn mibench_jpeg_ycbcr_to_rgb(raw: ?[*]const i64, n: usize, raw_out: ?[*]u8, cap: usize) i64 {
    if (raw == null or n < 4 or n > 49) return -1;
    const v = raw.?[0..n];
    if (v[0] < 1 or v[0] > 16 or n != 1 + 3 * @as(usize, @intCast(v[0]))) return -1;
    for (v[1..]) |x| if (x < 0 or x > 255) return -1;
    var staged: [48]u8 = @splat(0); var p: usize = 0;
    var i: usize = 1;
    while (i < n) : (i += 3) {
        const y=v[i]; const cb=v[i+1]-128; const cr=v[i+2]-128;
        staged[p]=clamp8(y+arshift16(91881*cr+32768)); p+=1;
        staged[p]=clamp8(y+arshift16(-22554*cb+32768-46802*cr)); p+=1;
        staged[p]=clamp8(y+arshift16(116130*cb+32768)); p+=1;
    }
    if (raw_out == null or cap < p) return -2;
    const out=raw_out.?; for (0..p) |j| out[j]=staged[j];
    return @intCast(p);
}
