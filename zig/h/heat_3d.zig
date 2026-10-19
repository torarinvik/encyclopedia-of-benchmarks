// PolyBench/C heat-3d bounded port. See benchmarks/h/heat_3d/LICENSE.txt.
const std=@import("std");

export fn polybench_heat_3d(input_opt:?[*]const f64,length:usize,output_opt:?[*]f64,capacity:usize) i64 {
    if(input_opt==null or length!=2)return -1;
    const input=input_opt.?;const nv=input[0];const sv=input[1];
    if(!std.math.isFinite(nv) or !std.math.isFinite(sv) or @trunc(nv)!=nv or @trunc(sv)!=sv or nv<1 or nv>6 or sv<0 or sv>4)return -1;
    const n:usize=@intFromFloat(nv);const steps:usize=@intFromFloat(sv);const cells=n*n*n;
    if(output_opt==null or capacity<cells)return -2;
    var a:[216]f64=@splat(0.0);var b:[216]f64=@splat(0.0);var staged:[216]f64=@splat(0.0);
    for(0..n)|i|for(0..n)|j|for(0..n)|k|{const q=i*n*n+j*n+k;a[q]=@as(f64,@floatFromInt(i+j+(n-k)))*10.0/@as(f64,@floatFromInt(n));b[q]=a[q];};
    for(0..steps)|_|{
        if(n>2){
            for(1..n-1)|i|for(1..n-1)|j|for(1..n-1)|k|{const q=i*n*n+j*n+k;const c=a[q];b[q]=0.125*(a[q+n*n]-2.0*c+a[q-n*n])+0.125*(a[q+n]-2.0*c+a[q-n])+0.125*(a[q+1]-2.0*c+a[q-1])+c;};
            for(1..n-1)|i|for(1..n-1)|j|for(1..n-1)|k|{const q=i*n*n+j*n+k;const c=b[q];a[q]=0.125*(b[q+n*n]-2.0*c+b[q-n*n])+0.125*(b[q+n]-2.0*c+b[q-n])+0.125*(b[q+1]-2.0*c+b[q-1])+c;};
        }
    }
    for(0..cells)|q|staged[q]=a[q];
    const output=output_opt.?;for(0..cells)|q|output[q]=staged[q];return @intCast(cells);
}
