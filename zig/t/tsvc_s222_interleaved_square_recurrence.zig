const std = @import("std");

fn seedOk(x: f64) bool { return x == -1 or x == -0.5 or x == 0 or x == 0.5 or x == 1; }

export fn tsvc_s222_interleaved_square_recurrence(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > 257) return -1;
    const input=input_opt.?; const rn=input[0];
    if (!std.math.isFinite(rn) or @trunc(rn)!=rn or rn<1 or rn>64) return -1;
    const n: usize=@intFromFloat(rn);
    if (length!=1+4*n) return -1;
    for (1..1+3*n) |i| if (!std.math.isFinite(input[i]) or @trunc(input[i])!=input[i] or @abs(input[i])>2) return -1;
    for (1+3*n..length) |i| if (!std.math.isFinite(input[i]) or !seedOk(input[i])) return -1;
    const required=2*n;
    if (output_opt==null or capacity<required) return -2;
    var a=[_]f64{0}**64; var e=[_]f64{0}**64;
    for (0..n) |i| { a[i]=input[1+i]; e[i]=input[1+3*n+i]; }
    for (1..n) |i| {
        const product=input[1+n+i]*input[1+2*n+i];
        a[i]=a[i]+product;
        e[i]=e[i-1]*e[i-1];
        a[i]=a[i]-product;
    }
    const output=output_opt.?;
    for (0..n) |i| { output[i]=a[i]; output[n+i]=e[i]; }
    return @intCast(required);
}
