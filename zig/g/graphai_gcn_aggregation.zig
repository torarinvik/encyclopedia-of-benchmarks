const std=@import("std");
export fn graphai_gcn_aggregation(input_opt:?[*]const f64,length:usize,output_opt:?[*]f64,capacity:usize)i64{
    const N:usize=8;const M:usize=24;const D:usize=4;const MAX_INPUT:usize=4+3*N+M+N*D;
    if(input_opt==null or length<7 or length>MAX_INPUT)return -1;const input=input_opt.?;
    for(0..length)|q|if(!std.math.isFinite(input[q]))return -1;
    const nv=input[0];const mv=input[1];const dv=input[2];
    if(@trunc(nv)!=nv or @trunc(mv)!=mv or @trunc(dv)!=dv or nv<1 or nv>8 or mv<0 or mv>24 or dv<1 or dv>4)return -1;
    const n:usize=@intFromFloat(nv);const m:usize=@intFromFloat(mv);const d:usize=@intFromFloat(dv);if(length!=4+3*n+m+n*d)return -1;
    const oa:usize=3;const ea=oa+n+1;const la=ea+m;const ra=la+n;const fa=ra+n;
    if(input[oa]!=0 or input[ea-1]!=@as(f64,@floatFromInt(m)))return -1;
    var rowptr:[N+1]usize=@splat(0);var colind:[M]usize=@splat(0);
    for(0..n+1)|i|{const x=input[oa+i];if(@trunc(x)!=x or x<0 or x>@as(f64,@floatFromInt(m)))return -1;rowptr[i]=@intFromFloat(x);if(i>0 and rowptr[i]<rowptr[i-1])return -1;}
    for(0..m)|e|{const x=input[ea+e];if(@trunc(x)!=x or x<0 or x>=@as(f64,@floatFromInt(n)))return -1;colind[e]=@intFromFloat(x);}
    for(0..n)|i|if(input[la+i]<-4 or input[la+i]>4 or input[ra+i]<-4 or input[ra+i]>4)return -1;
    for(0..n*d)|q|if(input[fa+q]<-8 or input[fa+q]>8)return -1;
    const required=n*d;if(output_opt==null or capacity<required)return -2;var staged:[N*D]f64=@splat(0);
    for(0..n)|src|{for(rowptr[src]..rowptr[src+1])|e|{const dst=colind[e];const w=input[la+src]*input[ra+dst];for(0..d)|k|staged[src*d+k]+=w*input[fa+dst*d+k];}}
    const output=output_opt.?;for(0..required)|q|output[q]=staged[q];return @intCast(required);
}
