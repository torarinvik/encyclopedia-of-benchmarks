package tsvc_s2275_matrix_vector_axpy_interleave
import "core:c"
import "core:math"
@(export) tsvc_s2275_matrix_vector_axpy_interleave :: proc "c"(x:[^]f64,l:c.size_t,y:[^]f64,cap:c.size_t)->i64{
 if x==nil||l<9||l>226 do return -1
 rn:=x[0];rp:=x[1];if rn!=rn||math.trunc(rn)!=rn||rn<1||rn>8||rp!=rp||math.trunc(rp)!=rp||rp<1||rp>8 do return -1
 n:=int(rn);passes:=int(rp);ms:=n*n;out_count:=ms+n;if l!=c.size_t(2+3*ms+4*n)do return -1
 for i:=2;i<int(l);i+=1{if x[i]!=x[i]||math.trunc(x[i])!=x[i]||math.abs(x[i])>1 do return -1}
 if y==nil||cap<c.size_t(out_count)do return -2
 var aa:[64]f64;var a:[8]f64;bb:=2+ms;cc:=2+2*ms;vec:=2+3*ms
 for i:=0;i<ms;i+=1{aa[i]=x[2+i]};for i:=0;i<n;i+=1{a[i]=x[vec+i]}
 for _:=0;_<passes;_+=1{for i:=0;i<n;i+=1{for j:=0;j<n;j+=1{k:=j*n+i;aa[k]=aa[k]+x[bb+k]*x[cc+k]};a[i]=x[vec+n+i]+x[vec+2*n+i]*x[vec+3*n+i]}}
 for i:=0;i<ms;i+=1{y[i]=aa[i]};for i:=0;i<n;i+=1{y[ms+i]=a[i]};return i64(out_count)
}
