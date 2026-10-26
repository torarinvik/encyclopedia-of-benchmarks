const std=@import("std");
export fn graphai_gat_aggregation(input_opt:?[*]const f64,length:usize,output_opt:?[*]f64,capacity:usize)i64{
    const N:usize=8;const M:usize=24;const D:usize=4;const MAX_INPUT:usize=4+N+M+2*D+N*D;
    if(input_opt==null or length<3 or length>MAX_INPUT)return -1;const input=input_opt.?;
    for(0..length)|q|if(!std.math.isFinite(input[q]))return -1;
    const nv=input[0];const mv=input[1];const dv=input[2];if(@trunc(nv)!=nv or @trunc(mv)!=mv or @trunc(dv)!=dv or nv<1 or nv>8 or mv<0 or mv>24 or dv<1 or dv>4)return -1;
    const n:usize=@intFromFloat(nv);const m:usize=@intFromFloat(mv);const d:usize=@intFromFloat(dv);if(length!=4+n+m+2*d+n*d)return -1;
    const rp:usize=3;const ci=rp+n+1;const al=ci+m;const ar=al+d;const xf=ar+d;if(input[rp]!=0 or input[ci-1]!=@as(f64,@floatFromInt(m)))return -1;
    var rows:[N+1]usize=@splat(0);var cols:[M]usize=@splat(0);
    for(0..n+1)|i|{const x=input[rp+i];if(@trunc(x)!=x or x<0 or x>@as(f64,@floatFromInt(m)))return -1;rows[i]=@intFromFloat(x);if(i>0 and rows[i]<rows[i-1])return -1;}
    for(0..m)|e|{const x=input[ci+e];if(@trunc(x)!=x or x<0 or x>=@as(f64,@floatFromInt(n)))return -1;cols[e]=@intFromFloat(x);}
    for(al..length)|q|if(input[q]<-8 or input[q]>8)return -1;
    const required=n*d;if(output_opt==null or capacity<required)return -2;var staged:[N*D]f64=@splat(0);var scores:[M]f64=@splat(0);var weights:[M]f64=@splat(0);
    for(0..n)|src|{const begin=rows[src];const end=rows[src+1];if(begin==end)continue;var maximum:f64=-1.0e300;
        for(begin..end)|e|{const dst=cols[e];var score:f64=0;for(0..d)|k|score+=input[al+k]*input[xf+src*d+k];for(0..d)|k|score+=input[ar+k]*input[xf+dst*d+k];scores[e]=if(score>0)score else 0.2*score;if(scores[e]>maximum)maximum=scores[e];}
        var total:f64=0;for(begin..end)|e|{weights[e]=@exp(scores[e]-maximum);total+=weights[e];}
        for(begin..end)|e|{const dst=cols[e];const scale=weights[e]/total;for(0..d)|k|staged[src*d+k]+=scale*input[xf+dst*d+k];}
    }
    const output=output_opt.?;for(0..required)|q|output[q]=staged[q];return @intCast(required);
}
