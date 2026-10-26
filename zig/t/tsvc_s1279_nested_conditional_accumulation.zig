const std=@import("std");
export fn tsvc_s1279_nested_conditional_accumulation(xo:?[*]const f64,l:usize,yo:?[*]f64,cap:usize)i64{
 if(xo==null or l<7 or l>322)return -1;const x=xo.?;const rn=x[0];const rp=x[1];
 if(!std.math.isFinite(rn)or @trunc(rn)!=rn or rn<1 or rn>64 or !std.math.isFinite(rp)or @trunc(rp)!=rp or rp<1 or rp>8)return -1;const n:usize=@intFromFloat(rn);const passes:usize=@intFromFloat(rp);if(l!=2+5*n)return -1;
 for(2..l)|i|{if(!std.math.isFinite(x[i])or @trunc(x[i])!=x[i]or @abs(x[i])>1)return -1;}if(yo==null or cap<n)return -2;const y=yo.?;var c:[64]f64=undefined;for(0..n)|i|{c[i]=x[2+2*n+i];}
 for(0..passes)|_|{for(0..n)|i|{const a=x[2+i];const b=x[2+n+i];if(a<0){if(b>a){c[i]+=x[2+3*n+i]*x[2+4*n+i];}}}}
 for(0..n)|i|{y[i]=c[i];}return @intCast(n);
}
