package tsvc_s482_break_after_update
import "core:c"
import "core:math"
@(export) tsvc_s482_break_after_update :: proc "c"(x:[^]f64,l:c.size_t,y:[^]f64,cap:c.size_t)->i64{
 if x==nil||l<5||l>194 do return -1
 rn:=x[0];rp:=x[1];if rn!=rn||math.trunc(rn)!=rn||rn<1||rn>64||rp!=rp||math.trunc(rp)!=rp||rp<1||rp>8 do return -1
 n:=int(rn);passes:=int(rp);if l!=c.size_t(2+3*n)do return -1
 for i:=2;i<int(l);i+=1{if x[i]!=x[i]||math.trunc(x[i])!=x[i]||math.abs(x[i])>1 do return -1}
 if y==nil||cap<c.size_t(n)do return -2
 var a:[64]f64;bb:=2+n;cc:=2+2*n;for i:=0;i<n;i+=1{a[i]=x[2+i]}
 for _:=0;_<passes;_+=1{for i:=0;i<n;i+=1{a[i]+=x[bb+i]*x[cc+i];if x[cc+i]>x[bb+i]do break}}
 for i:=0;i<n;i+=1{y[i]=a[i]};return i64(n)
}
