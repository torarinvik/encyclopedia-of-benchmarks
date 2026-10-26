const std=@import("std");
export fn graphai_cf_sgd_sweep(input_opt:?[*]const f64,length:usize,output_opt:?[*]f64,capacity:usize)i64{
    const N:usize=8;const M:usize=24;const K:usize=4;const MAX_INPUT:usize=7+N+2*M+N*K;
    if(input_opt==null or length<6 or length>MAX_INPUT)return -1;const input=input_opt.?;
    for(0..length)|q|if(!std.math.isFinite(input[q]))return -1;
    const uv=input[0];const iv=input[1];const mv=input[2];const kv=input[3];if(@trunc(uv)!=uv or @trunc(iv)!=iv or @trunc(mv)!=mv or @trunc(kv)!=kv or uv<1 or uv>7 or iv<1 or iv>7 or mv<0 or mv>24 or kv<1 or kv>4)return -1;
    const users:usize=@intFromFloat(uv);const items:usize=@intFromFloat(iv);const n=users+items;const m:usize=@intFromFloat(mv);const k:usize=@intFromFloat(kv);const lambda=input[4];const step=input[5];
    if(n>N or lambda<0 or lambda>1 or step<0 or step>0.01 or length!=7+n+2*m+n*k)return -1;
    const rp:usize=6;const ci=rp+n+1;const ra=ci+m;const la=ra+m;if(input[rp]!=0 or input[ci-1]!=@as(f64,@floatFromInt(m)))return -1;
    var rows:[N+1]usize=@splat(0);var cols:[M]usize=@splat(0);
    for(0..n+1)|i|{const x=input[rp+i];if(@trunc(x)!=x or x<0 or x>@as(f64,@floatFromInt(m)))return -1;rows[i]=@intFromFloat(x);if(i>0 and rows[i]<rows[i-1])return -1;}
    for(users..n)|u|if(rows[u]!=rows[u+1])return -1;
    for(0..m)|e|{const x=input[ci+e];if(@trunc(x)!=x or x<@as(f64,@floatFromInt(users)) or x>=@as(f64,@floatFromInt(n)))return -1;cols[e]=@intFromFloat(x);}
    for(0..m)|e|if(input[ra+e]<-4 or input[ra+e]>4)return -1;
    for(0..n*k)|q|if(input[la+q]<-2 or input[la+q]>2)return -1;
    const required=n*k;if(output_opt==null or capacity<required)return -2;var error:[N*K]f64=@splat(0);var staged:[N*K]f64=@splat(0);
    for(0..users)|u|{for(rows[u]..rows[u+1])|e|{const v=cols[e];var estimate:f64=0;for(0..k)|j|estimate+=input[la+u*k+j]*input[la+v*k+j];const delta=input[ra+e]-estimate;for(0..k)|j|error[u*k+j]+=input[la+v*k+j]*delta;}}
    for(0..n)|v|{for(0..k)|j|{const q=v*k+j;staged[q]=input[la+q]+step*(-lambda*input[la+q]+error[q]);}}
    const output=output_opt.?;for(0..required)|q|output[q]=staged[q];return @intCast(required);
}
