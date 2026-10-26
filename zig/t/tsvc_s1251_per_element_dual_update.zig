const std=@import("std");
export fn tsvc_s1251_per_element_dual_update(xo:?[*]const f64,l:usize,yo:?[*]f64,c:usize)i64 {
    if(xo==null or l<6 or l>321)return -1;const x=xo.?;const r=x[0];
    if(!std.math.isFinite(r) or @trunc(r)!=r or r<1 or r>64)return -1;const n:usize=@intFromFloat(r);
    if(l!=1+5*n)return -1;for(1..l)|i|{if(!std.math.isFinite(x[i]) or @trunc(x[i])!=x[i] or @abs(x[i])>1)return -1;}
    if(yo==null or c<2*n)return -2;const y=yo.?;var a:[64]f64=undefined;var b:[64]f64=undefined;
    for(0..n)|i|{const saved=x[1+n+i]+x[1+2*n+i];b[i]=x[1+i]+x[1+3*n+i];a[i]=saved*x[1+4*n+i];}
    for(0..n)|i|{y[i]=a[i];y[n+i]=b[i];}return @intCast(2*n);
}
