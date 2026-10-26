const std=@import("std");
export fn graphai_sage_aggregation(input_opt:?[*]const f64,length:usize,output_opt:?[*]f64,capacity:usize)i64{
    const N:usize=8;const M:usize=24;const D:usize=4;const MAX_INPUT:usize=4+N+M+N*D;
    if(input_opt==null or length<4 or length>MAX_INPUT)return -1;const input=input_opt.?;
    for(0..length)|q|if(!std.math.isFinite(input[q]))return -1;
    const nv=input[0];const mv=input[1];const dv=input[2];if(@trunc(nv)!=nv or @trunc(mv)!=mv or @trunc(dv)!=dv or nv<1 or nv>8 or mv<0 or mv>24 or dv<1 or dv>4)return -1;
    const n:usize=@intFromFloat(nv);const m:usize=@intFromFloat(mv);const d:usize=@intFromFloat(dv);if(length!=4+n+m+n*d)return -1;
    const rp:usize=3;const ci=rp+n+1;const xf=ci+m;if(input[rp]!=0 or input[ci-1]!=@as(f64,@floatFromInt(m)))return -1;
    var rows:[N+1]usize=@splat(0);var cols:[M]usize=@splat(0);
    for(0..n+1)|i|{const x=input[rp+i];if(@trunc(x)!=x or x<0 or x>@as(f64,@floatFromInt(m)))return -1;rows[i]=@intFromFloat(x);if(i>0 and rows[i]<rows[i-1])return -1;}
    for(0..m)|e|{const x=input[ci+e];if(@trunc(x)!=x or x<0 or x>=@as(f64,@floatFromInt(n)))return -1;cols[e]=@intFromFloat(x);}
    for(0..n*d)|q|if(input[xf+q]<-8 or input[xf+q]>8)return -1;
    const required=n*d;if(output_opt==null or capacity<required)return -2;var staged:[N*D]f64=@splat(0);
    for(0..n)|src|{const degree=rows[src+1]-rows[src];if(degree>0){const scale=1.0/@as(f64,@floatFromInt(degree));for(rows[src]..rows[src+1])|e|{const dst=cols[e];for(0..d)|k|staged[src*d+k]+=scale*input[xf+dst*d+k];}}}
    const output=output_opt.?;for(0..required)|q|output[q]=staged[q];return @intCast(required);
}
