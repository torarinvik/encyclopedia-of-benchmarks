package tsvc_s2710_nested_scalar_vector_branch_update
import "core:c"
import "core:math"
@(export) tsvc_s2710_nested_scalar_vector_branch_update :: proc "c"(x:[^]f64,l:c.size_t,y:[^]f64,cap:c.size_t)->i64{
 if x==nil||l<58||l>323 do return -1
 rn:=x[0];rp:=x[1];scalar:=x[2];if rn!=rn||math.trunc(rn)!=rn||rn<11||rn>64||rp!=rp||math.trunc(rp)!=rp||rp<1||rp>8||scalar!=scalar||math.trunc(scalar)!=scalar||math.abs(scalar)>1 do return -1
 n:=int(rn);passes:=int(rp);if l!=c.size_t(3+5*n)do return -1
 for i:=3;i<int(l);i+=1{if x[i]!=x[i]||math.trunc(x[i])!=x[i]||math.abs(x[i])>1 do return -1}
 if y==nil||cap<c.size_t(3*n)do return -2
 var a,b,c:[64]f64;for i:=0;i<n;i+=1{a[i]=x[3+i];b[i]=x[3+n+i];c[i]=x[3+2*n+i]}
 for _:=0;_<passes;_+=1{for i:=0;i<n;i+=1{d:=x[3+3*n+i];e:=x[3+4*n+i];if a[i]>b[i]{a[i]+=b[i]*d;c[i]+=d*d}else{b[i]=a[i]+e*e;if scalar>0{c[i]=a[i]+d*d}else{c[i]+=e*e}}}}
 for i:=0;i<n;i+=1{y[i]=a[i];y[n+i]=b[i];y[2*n+i]=c[i]};return i64(3*n)
}
