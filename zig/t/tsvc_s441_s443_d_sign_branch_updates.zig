const std=@import("std");
export fn tsvc_s441_s443_d_sign_branch_updates(xo:?[*]const f64,l:usize,yo:?[*]f64,cap:usize)i64{
 if(xo==null or l<7 or l>259)return -1;const x=xo.?;const mr=x[0];const rn=x[1];const rp=x[2];
 if(!std.math.isFinite(mr)or @trunc(mr)!=mr or (mr!=0 and mr!=1)or !std.math.isFinite(rn)or @trunc(rn)!=rn or rn<1 or rn>64 or !std.math.isFinite(rp)or @trunc(rp)!=rp or rp<1 or rp>8)return -1;const mode:usize=@intFromFloat(mr);const n:usize=@intFromFloat(rn);const passes:usize=@intFromFloat(rp);if(l!=3+4*n)return -1;
 for(3..l)|i|{if(!std.math.isFinite(x[i])or @trunc(x[i])!=x[i]or @abs(x[i])>1)return -1;}if(yo==null or cap<n)return -2;const y=yo.?;var a:[64]f64=undefined;const b=3+n;const c=3+2*n;const d=3+3*n;for(0..n)|i|{a[i]=x[3+i];}
 for(0..passes)|_|{for(0..n)|i|{if(mode==0){if(x[d+i]<0){a[i]+=x[b+i]*x[c+i];}else if(x[d+i]==0){a[i]+=x[b+i]*x[b+i];}else{a[i]+=x[c+i]*x[c+i];}}else if(x[d+i]<=0){a[i]+=x[b+i]*x[c+i];}else{a[i]+=x[b+i]*x[b+i];}}}
 for(0..n)|i|{y[i]=a[i];}return @intCast(n);
}
