const std = @import("std");

export fn graphai_ggnn_message_update(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    const N: usize=8; const M: usize=24; const D: usize=4;
    if (input_opt==null or length<3 or length>453) return -1;
    const input=input_opt.?;
    for (0..length) |q| if (!std.math.isFinite(input[q])) return -1;
    const nv=input[0]; const mv=input[1]; const dv=input[2];
    if (@trunc(nv)!=nv or @trunc(mv)!=mv or @trunc(dv)!=dv or
        nv<1 or nv>8 or mv<0 or mv>24 or dv<1 or dv>4) return -1;
    const n: usize=@intFromFloat(nv); const m: usize=@intFromFloat(mv); const d: usize=@intFromFloat(dv);
    if (length!=4+n+m+n*d+6*n*n) return -1;
    const row_at: usize=3; const col_at=row_at+n+1; const h_at=col_at+m;
    const wz_at=h_at+n*d; const wr_at=wz_at+n*n; const wc_at=wr_at+n*n;
    const uz_at=wc_at+n*n; const ur_at=uz_at+n*n; const uc_at=ur_at+n*n;
    if (input[row_at]!=0 or input[col_at-1]!=@as(f64,@floatFromInt(m))) return -1;
    var rows: [N+1]usize=@splat(0); var cols: [M]usize=@splat(0);
    for (0..n+1) |i| { const x=input[row_at+i]; if (@trunc(x)!=x or x<0 or x>@as(f64,@floatFromInt(m))) return -1; rows[i]=@intFromFloat(x); if (i>0 and rows[i]<rows[i-1]) return -1; }
    for (0..m) |e| { const x=input[col_at+e]; if (@trunc(x)!=x or x<0 or x>=@as(f64,@floatFromInt(n))) return -1; cols[e]=@intFromFloat(x); }
    for (h_at..wz_at) |q| if (input[q] < -1 or input[q] > 1) return -1;
    for (wz_at..length) |q| if (input[q] < -0.25 or input[q] > 0.25) return -1;
    const required=n*d; if (output_opt==null or capacity<required) return -2;
    var agg: [N*D]f64=@splat(0); var update: [N*D]f64=@splat(0); var reset: [N*D]f64=@splat(0);
    var candidate: [N*D]f64=@splat(0); var staged: [N*D]f64=@splat(0);
    for (0..n) |v| {
        for (rows[v]..rows[v+1]) |e| {
            for (0..d) |f| { agg[v*d+f] += input[h_at+cols[e]*d+f]; }
        }
    }
    for (0..n) |v| {
        for (0..d) |f| {
            var wz: f64=0; var wr: f64=0; var uz: f64=0; var ur: f64=0;
            for (0..n) |k| {
                const a=v*n+k; const b=k*d+f;
                wz+=input[wz_at+a]*agg[b]; wr+=input[wr_at+a]*agg[b];
                uz+=input[uz_at+a]*input[h_at+b]; ur+=input[ur_at+a]*input[h_at+b];
            }
            const at=v*d+f;
            update[at]=1.0/(1.0+@exp(-(wz+uz)));
            reset[at]=1.0/(1.0+@exp(-(wr+ur)));
        }
    }
    for (0..n) |v| {
        for (0..d) |f| {
            var graph: f64=0; var state: f64=0;
            for (0..n) |k| {
                const a=v*n+k; const b=k*d+f;
                graph+=input[wc_at+a]*agg[b]; state+=input[uc_at+a]*(reset[b]*input[h_at+b]);
            }
            const at=v*d+f; const x=graph+state;
            candidate[at]=2.0/(1.0+@exp(-2.0*x))-1.0;
            staged[at]=(1.0-update[at])*input[h_at+at]+update[at]*candidate[at];
        }
    }
    const output=output_opt.?; for (0..required) |q| output[q]=staged[q];
    return @intCast(required);
}
