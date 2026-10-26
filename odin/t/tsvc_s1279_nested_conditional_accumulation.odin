package tsvc_s1279_nested_conditional_accumulation
import "core:c"
import "core:math"
@(export) tsvc_s1279_nested_conditional_accumulation :: proc "c"(x:[^]f64,l:c.size_t,y:[^]f64,cap:c.size_t)->i64{
 if x==nil||l<7||l>322 do return -1
 rn:=x[0];rp:=x[1]
 if rn!=rn||math.trunc(rn)!=rn||rn<1||rn>64||rp!=rp||math.trunc(rp)!=rp||rp<1||rp>8 do return -1
 n:=int(rn);passes:=int(rp);if l!=c.size_t(2+5*n)do return -1
 for i:=2;i<int(l);i+=1{if x[i]!=x[i]||math.trunc(x[i])!=x[i]||math.abs(x[i])>1 do return -1}
 if y==nil||cap<c.size_t(n)do return -2
 var cbuf:[64]f64;for i:=0;i<n;i+=1{cbuf[i]=x[2+2*n+i]}
 for _:=0;_<passes;_+=1{for i:=0;i<n;i+=1{a:=x[2+i];b:=x[2+n+i];if a<0{if b>a{cbuf[i]+=x[2+3*n+i]*x[2+4*n+i]}}}}
 for i:=0;i<n;i+=1{y[i]=cbuf[i]};return i64(n)
}
