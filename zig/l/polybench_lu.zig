// PolyBench/C lu bounded port. See benchmarks/l/polybench_lu/LICENSE.txt.
const std=@import("std");
export fn polybench_lu(input_opt:?[*]const f64,length:usize,output_opt:?[*]f64,capacity:usize)i64{
    if(input_opt==null or length!=1)return -1;
    const input=input_opt.?;const nv=input[0];
    if(!std.math.isFinite(nv) or @trunc(nv)!=nv or nv<1 or nv>6)return -1;
    const n:usize=@intFromFloat(nv);const cells=n*n;
    if(output_opt==null or capacity<cells)return -2;
    var a:[36]f64=@splat(0.0);var base:[36]f64=@splat(0.0);var staged:[36]f64=@splat(0.0);
    for(0..n)|i|{for(0..i)|j|base[i*n+j]=1.0-@as(f64,@floatFromInt(j))/@as(f64,@floatFromInt(n));base[i*n+i]=1.0;}
    for(0..n)|t|for(0..n)|r|for(0..n)|s|a[r*n+s]+=base[r*n+t]*base[s*n+t];
    for(0..n)|i|{
        for(0..i)|j|{for(0..j)|k|a[i*n+j]-=a[i*n+k]*a[k*n+j];a[i*n+j]/=a[j*n+j];}
        for(i..n)|j|for(0..i)|k|a[i*n+j]-=a[i*n+k]*a[k*n+j];
    }
    for(0..cells)|q|staged[q]=a[q];
    const output=output_opt.?;for(0..cells)|q|output[q]=staged[q];return @intCast(cells);
}
