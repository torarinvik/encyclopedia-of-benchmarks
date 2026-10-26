const std=@import("std");
export fn tsvc_s2275_matrix_vector_axpy_interleave(xo:?[*]const f64,l:usize,yo:?[*]f64,cap:usize)i64{
 if(xo==null or l<9 or l>226)return -1;const x=xo.?;const rn=x[0];const rp=x[1];
 if(!std.math.isFinite(rn)or @trunc(rn)!=rn or rn<1 or rn>8 or !std.math.isFinite(rp)or @trunc(rp)!=rp or rp<1 or rp>8)return -1;const n:usize=@intFromFloat(rn);const passes:usize=@intFromFloat(rp);const ms=n*n;const out_count=ms+n;if(l!=2+3*ms+4*n)return -1;
 for(2..l)|i|{if(!std.math.isFinite(x[i])or @trunc(x[i])!=x[i]or @abs(x[i])>1)return -1;}if(yo==null or cap<out_count)return -2;const y=yo.?;var aa:[64]f64=undefined;var a:[8]f64=undefined;const bb=2+ms;const cc=2+2*ms;const vec=2+3*ms;for(0..ms)|i|{aa[i]=x[2+i];}for(0..n)|i|{a[i]=x[vec+i];}
 for(0..passes)|_|{for(0..n)|i|{for(0..n)|j|{const k=j*n+i;aa[k]=aa[k]+x[bb+k]*x[cc+k];}a[i]=x[vec+n+i]+x[vec+2*n+i]*x[vec+3*n+i];}}
 for(0..ms)|i|{y[i]=aa[i];}for(0..n)|i|{y[ms+i]=a[i];}return @intCast(out_count);
}
