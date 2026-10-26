package tsvc_s242_fused_prefix_update
import "core:c"
import "core:math"
@(export) tsvc_s242_fused_prefix_update :: proc "c"(x:[^]f64,l:c.size_t,y:[^]f64,cap:c.size_t)->i64{if x==nil||l<7||l>259 do return -1;r:=x[0];if r!=r||math.trunc(r)!=r||r<1||r>64 do return -1;n:=int(r);if l!=c.size_t(3+4*n) do return -1;for i:=1;i<int(l);i+=1{if x[i]!=x[i]||math.trunc(x[i])!=x[i]||math.abs(x[i])>1 do return -1};if y==nil||cap<c.size_t(n) do return -2;var a:[64]f64;for i:=0;i<n;i+=1{a[i]=x[3+i]};for i:=1;i<n;i+=1{v:=a[i-1]+x[1];v+=x[2];v+=x[3+2*n+i];v+=x[3+3*n+i];v+=x[3+4*n+i];a[i]=v};for i:=0;i<n;i+=1{y[i]=a[i]};return i64(n)}
