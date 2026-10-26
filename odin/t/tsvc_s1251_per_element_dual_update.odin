package tsvc_s1251_per_element_dual_update
import "core:c"
import "core:math"
@(export) tsvc_s1251_per_element_dual_update :: proc "c"(x:[^]f64,l:c.size_t,y:[^]f64,capa:c.size_t)->i64 {
 if x==nil||l<6||l>321 do return -1
 r:=x[0];if r!=r||math.trunc(r)!=r||r<1||r>64 do return -1
 n:=int(r);if l!=c.size_t(1+5*n) do return -1
 for i:=1;i<int(l);i+=1 {if x[i]!=x[i]||math.trunc(x[i])!=x[i]||math.abs(x[i])>1 do return -1}
 if y==nil||capa<c.size_t(2*n) do return -2
 var a,b:[64]f64
 for i:=0;i<n;i+=1 {saved:=x[1+n+i]+x[1+2*n+i];b[i]=x[1+i]+x[1+3*n+i];a[i]=saved*x[1+4*n+i]}
 for i:=0;i<n;i+=1 {y[i]=a[i];y[n+i]=b[i]}
 return i64(2*n)
}
