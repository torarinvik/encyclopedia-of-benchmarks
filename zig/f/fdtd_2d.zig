// PolyBench/C fdtd-2d bounded port. See benchmarks/f/fdtd_2d/LICENSE.txt.
const std = @import("std");
const MAX_NX: usize=6;
const MAX_NY: usize=6;
const MAX_TMAX: usize=4;

export fn fdtd_2d(input_opt:?[*]const f64,length:usize,output_opt:?[*]f64,capacity:usize) i64 {
    if(input_opt==null or length!=3)return -1;
    const input=input_opt.?;
    for(0..3)|q|if(!std.math.isFinite(input[q]) or @trunc(input[q])!=input[q])return -1;
    if(input[0]<0 or input[0]>@as(f64,@floatFromInt(MAX_TMAX)) or input[1]<1 or input[1]>@as(f64,@floatFromInt(MAX_NX)) or input[2]<1 or input[2]>@as(f64,@floatFromInt(MAX_NY)))return -1;
    const tmax:usize=@intFromFloat(input[0]);const nx:usize=@intFromFloat(input[1]);const ny:usize=@intFromFloat(input[2]);
    const n=nx*ny;const required=3*n;
    if(output_opt==null or capacity<required)return -2;
    var ex:[MAX_NX*MAX_NY]f64=@splat(0.0);var ey:[MAX_NX*MAX_NY]f64=@splat(0.0);var hz:[MAX_NX*MAX_NY]f64=@splat(0.0);
    var fict:[MAX_TMAX]f64=@splat(0.0);var staged:[3*MAX_NX*MAX_NY]f64=@splat(0.0);
    for(0..tmax)|t|fict[t]=@floatFromInt(t);
    for(0..nx)|i|for(0..ny)|j|{
        ex[i*ny+j]=@as(f64,@floatFromInt(i*(j+1)))/@as(f64,@floatFromInt(nx));
        ey[i*ny+j]=@as(f64,@floatFromInt(i*(j+2)))/@as(f64,@floatFromInt(ny));
        hz[i*ny+j]=@as(f64,@floatFromInt(i*(j+3)))/@as(f64,@floatFromInt(nx));
    };
    for(0..tmax)|t|{
        for(0..ny)|j|ey[j]=fict[t];
        for(1..nx)|i|for(0..ny)|j|ey[i*ny+j]=ey[i*ny+j]-0.5*(hz[i*ny+j]-hz[(i-1)*ny+j]);
        for(0..nx)|i|for(1..ny)|j|ex[i*ny+j]=ex[i*ny+j]-0.5*(hz[i*ny+j]-hz[i*ny+j-1]);
        if(nx>1 and ny>1)for(0..nx-1)|i|for(0..ny-1)|j|hz[i*ny+j]=hz[i*ny+j]-0.7*((ex[i*ny+j+1]-ex[i*ny+j])+(ey[(i+1)*ny+j]-ey[i*ny+j]));
    }
    for(0..n)|i|{staged[i]=ex[i];staged[n+i]=ey[i];staged[2*n+i]=hz[i];}
    const output=output_opt.?;for(0..required)|i|output[i]=staged[i];return @intCast(required);
}
