const std = @import("std");
const SQRT2: f64 = 1.414213562373095048801688724209698079;

export fn cbench_lame_mid_side(raw: ?[*]const f64, n: usize, raw_out: ?[*]f64, cap: usize) i64 {
    if (raw == null or n == 0 or n > 66) return -1;
    const input=raw.?[0..n];
    for (input) |x| if (!std.math.isFinite(x)) return -1;
    if (input[0] < 1.0 or input[0] > 32.0 or @trunc(input[0]) != input[0]) return -1;
    const count: usize=@intFromFloat(input[0]);
    if (n != 1+2*count) return -1;
    for (input[1..]) |x| if (x < -16.0 or x > 16.0) return -1;
    var staged: [64]f64 = @splat(0.0);
    const factor=SQRT2*0.5;
    for (0..count) |i| {
        const left=input[1+i]; const right=input[1+count+i];
        staged[2*i]=(left+right)*factor;
        staged[2*i+1]=(left-right)*factor;
    }
    const needed=2*count;
    if (raw_out == null or cap<needed) return -2;
    const output=raw_out.?;
    for (0..needed) |i| output[i]=staged[i];
    return @intCast(needed);
}
