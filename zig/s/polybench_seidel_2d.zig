// PolyBench/C seidel-2d bounded port. See benchmarks/s/polybench_seidel_2d/LICENSE.txt.
const std=@import("std");
export fn polybench_seidel_2d(input_opt:?[*]const f64,length:usize,output_opt:?[*]f64,capacity:usize)i64{
    if(input_opt==null or length!=2)return -1;
    const input=input_opt.?;const nv=input[0];const sv=input[1];
    if(!std.math.isFinite(nv) or !std.math.isFinite(sv) or @trunc(nv)!=nv or @trunc(sv)!=sv or nv<1 or nv>6 or sv<0 or sv>4)return -1;
    const n:usize=@intFromFloat(nv);const steps:usize=@intFromFloat(sv);const cells=n*n;
    if(output_opt==null or capacity<cells)return -2;
    var a:[36]f64=@splat(0.0);var staged:[36]f64=@splat(0.0);
    for(0..n)|i|for(0..n)|j|a[i*n+j]=(@as(f64,@floatFromInt(i))*@as(f64,@floatFromInt(j+2))+2.0)/@as(f64,@floatFromInt(n));
    for(0..steps)|_|{
        if(n>2)for(1..n-1)|i|for(1..n-1)|j|{const q=i*n+j;const total=a[q-n-1]+a[q-n]+a[q-n+1]+a[q-1]+a[q]+a[q+1]+a[q+n-1]+a[q+n]+a[q+n+1];a[q]=total/9.0;};
    }
    for(0..cells)|q|staged[q]=a[q];
    const output=output_opt.?;for(0..cells)|q|output[q]=staged[q];return @intCast(cells);
}
