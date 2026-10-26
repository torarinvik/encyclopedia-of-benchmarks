const std=@import("std");
export fn tsvc_s482_break_after_update(xo:?[*]const f64,l:usize,yo:?[*]f64,cap:usize)i64{
 if(xo==null or l<5 or l>194)return -1;const x=xo.?;const rn=x[0];const rp=x[1];
 if(!std.math.isFinite(rn)or @trunc(rn)!=rn or rn<1 or rn>64 or !std.math.isFinite(rp)or @trunc(rp)!=rp or rp<1 or rp>8)return -1;const n:usize=@intFromFloat(rn);const passes:usize=@intFromFloat(rp);if(l!=2+3*n)return -1;
 for(2..l)|i|{if(!std.math.isFinite(x[i])or @trunc(x[i])!=x[i]or @abs(x[i])>1)return -1;}if(yo==null or cap<n)return -2;const y=yo.?;const b=2+n;const c=2+2*n;var a:[64]f64=undefined;for(0..n)|i|{a[i]=x[2+i];}
 for(0..passes)|_|{for(0..n)|i|{a[i]+=x[b+i]*x[c+i];if(x[c+i]>x[b+i])break;}}
 for(0..n)|i|{y[i]=a[i];}return @intCast(n);
}
