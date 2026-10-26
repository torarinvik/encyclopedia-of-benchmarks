const std=@import("std");
export fn tsvc_s2710_nested_scalar_vector_branch_update(xo:?[*]const f64,l:usize,yo:?[*]f64,cap:usize)i64{
 if(xo==null or l<58 or l>323)return -1;const x=xo.?;const rn=x[0];const rp=x[1];const scalar=x[2];
 if(!std.math.isFinite(rn)or @trunc(rn)!=rn or rn<11 or rn>64 or !std.math.isFinite(rp)or @trunc(rp)!=rp or rp<1 or rp>8 or !std.math.isFinite(scalar)or @trunc(scalar)!=scalar or @abs(scalar)>1)return -1;const n:usize=@intFromFloat(rn);const passes:usize=@intFromFloat(rp);if(l!=3+5*n)return -1;
 for(3..l)|i|{if(!std.math.isFinite(x[i])or @trunc(x[i])!=x[i]or @abs(x[i])>1)return -1;}if(yo==null or cap<3*n)return -2;const y=yo.?;var a:[64]f64=undefined;var b:[64]f64=undefined;var c:[64]f64=undefined;for(0..n)|i|{a[i]=x[3+i];b[i]=x[3+n+i];c[i]=x[3+2*n+i];}
 for(0..passes)|_|{for(0..n)|i|{const d=x[3+3*n+i];const e=x[3+4*n+i];if(a[i]>b[i]){a[i]+=b[i]*d;c[i]+=d*d;}else{b[i]=a[i]+e*e;if(scalar>0){c[i]=a[i]+d*d;}else{c[i]+=e*e;}}}}
 for(0..n)|i|{y[i]=a[i];y[n+i]=b[i];y[2*n+i]=c[i];}return @intCast(3*n);
}
