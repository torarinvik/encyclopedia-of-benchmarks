const std=@import("std");
export fn graphai_frontier_sampler(input_opt:?[*]const f64,length:usize,output_opt:?[*]f64,capacity:usize)i64{
    const N:usize=8;const M:usize=24;const R:usize=4;const MAX_INPUT:usize=4+N+M+22*R;
    if(input_opt==null or length<3 or length>MAX_INPUT)return -1;const input=input_opt.?;
    for(0..length)|q|if(!std.math.isFinite(input[q]))return -1;
    const nv=input[0];const mv=input[1];const rv=input[2];if(@trunc(nv)!=nv or @trunc(mv)!=mv or @trunc(rv)!=rv or nv<1 or nv>8 or mv<0 or mv>24 or rv<1 or rv>4)return -1;
    const n:usize=@intFromFloat(nv);const m:usize=@intFromFloat(mv);const r:usize=@intFromFloat(rv);const required=22*r;if(length!=4+n+m+22*r)return -1;
    const root_at:usize=3;const row_at=root_at+r;const col_at=row_at+n+1;const choice_at=col_at+m;
    var rows:[N+1]usize=@splat(0);var cols:[M]usize=@splat(0);var front:[R*12]usize=@splat(0);var next:[R*12]usize=@splat(0);var staged:[R*22]f64=@splat(0);
    for(0..r)|i|{const x=input[root_at+i];if(@trunc(x)!=x or x<0 or x>=@as(f64,@floatFromInt(n)))return -1;front[i]=@intFromFloat(x);staged[i]=x;}
    if(input[row_at]!=0 or input[col_at-1]!=@as(f64,@floatFromInt(m)))return -1;
    for(0..n+1)|i|{const x=input[row_at+i];if(@trunc(x)!=x or x<0 or x>@as(f64,@floatFromInt(m)))return -1;rows[i]=@intFromFloat(x);if(i>0 and rows[i]<rows[i-1])return -1;}
    for(0..m)|e|{const x=input[col_at+e];if(@trunc(x)!=x or x<0 or x>=@as(f64,@floatFromInt(n)))return -1;cols[e]=@intFromFloat(x);}
    if(output_opt==null or capacity<required)return -2;
    const fanouts=[_]usize{3,2,2};var front_size=r;var choice:usize=0;var out_at=r;
    for(fanouts)|fanout|{const next_size=front_size*fanout;for(0..front_size)|i|{const parent=front[i];const begin=rows[parent];const degree=rows[parent+1]-begin;if(degree==0)return -1;
        for(0..fanout)|j|{const x=input[choice_at+choice];choice+=1;if(@trunc(x)!=x or x<0 or x>=@as(f64,@floatFromInt(degree)))return -1;const vertex=cols[begin+@as(usize,@intFromFloat(x))];next[i*fanout+j]=vertex;staged[out_at]=@floatFromInt(vertex);out_at+=1;}}
        for(0..next_size)|i|front[i]=next[i];front_size=next_size;}
    if(choice!=21*r or out_at!=required)return -1;const output=output_opt.?;for(0..required)|q|output[q]=staged[q];return @intCast(required);
}
