// PolyBench/C correlation bounded port. See benchmarks/c/polybench_correlation/LICENSE.txt.
const std=@import("std");
export fn polybench_correlation(input_opt:?[*]const f64,length:usize,output_opt:?[*]f64,capacity:usize)i64{
    if(input_opt==null or length!=2)return -1;
    const input=input_opt.?;const nv=input[0];const mv=input[1];
    if(!std.math.isFinite(nv) or !std.math.isFinite(mv) or @trunc(nv)!=nv or @trunc(mv)!=mv or nv<1 or nv>6 or mv<1 or mv>6)return -1;
    const n:usize=@intFromFloat(nv);const m:usize=@intFromFloat(mv);const required=m*m;
    if(output_opt==null or capacity<required)return -2;
    var data:[36]f64=@splat(0.0);var corr:[36]f64=@splat(0.0);var mean:[6]f64=@splat(0.0);var stddev:[6]f64=@splat(0.0);var staged:[36]f64=@splat(0.0);const float_n=@as(f64,@floatFromInt(n));
    for(0..n)|i|for(0..m)|j|data[i*m+j]=@as(f64,@floatFromInt(i*j))/@as(f64,@floatFromInt(m))+@as(f64,@floatFromInt(i));
    for(0..m)|j|{mean[j]=0.0;for(0..n)|i|mean[j]+=data[i*m+j];mean[j]/=float_n;}
    for(0..m)|j|{stddev[j]=0.0;for(0..n)|i|{const d=data[i*m+j]-mean[j];stddev[j]+=d*d;}stddev[j]/=float_n;stddev[j]=std.math.sqrt(stddev[j]);if(stddev[j]<=0.1)stddev[j]=1.0;}
    const root_n=std.math.sqrt(float_n);for(0..n)|i|for(0..m)|j|{data[i*m+j]-=mean[j];data[i*m+j]/=root_n*stddev[j];};
    if(m>1){for(0..m-1)|i|{corr[i*m+i]=1.0;for(i+1..m)|j|{corr[i*m+j]=0.0;for(0..n)|k|corr[i*m+j]+=data[k*m+i]*data[k*m+j];corr[j*m+i]=corr[i*m+j];}}}
    corr[(m-1)*m+m-1]=1.0;for(0..required)|q|staged[q]=corr[q];const output=output_opt.?;for(0..required)|q|output[q]=staged[q];return @intCast(required);
}
