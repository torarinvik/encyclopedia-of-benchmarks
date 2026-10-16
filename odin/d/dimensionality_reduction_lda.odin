package dimensionality_reduction_lda
import "core:c"
import "core:math"
@(export)
dimensionality_reduction_lda :: proc "c" (v:[^]f64,n0:c.size_t,out:[^]f64,cap0:c.size_t)->i64 {
 n:=int(n0);cap:=int(cap0);if v==nil||n<16||v[0]!=2||v[2]!=2||v[3]!=1||v[1]<4||v[1]>8||math.floor(v[1])!=v[1]{return -1};m:=int(v[1]);if n!=4+3*m{return -1};base:=4+2*m
 x:[8]f64;y:[8]f64;means:[2][2]f64;counts:[2]int
 for i:=0;i<m;i+=1{x[i]=v[4+i];y[i]=v[4+m+i];lab:=v[base+i];if x[i]!=x[i]||y[i]!=y[i]||math.abs(x[i])>10000||math.abs(y[i])>10000||(lab!=0&&lab!=1){return -1};c:=int(lab);counts[c]+=1;means[c][0]+=x[i];means[c][1]+=y[i]}
 if counts[0]<2||counts[1]<2{return -1};for c:=0;c<2;c+=1{means[c][0]/=f64(counts[c]);means[c][1]/=f64(counts[c])};a:=0.0;b:=0.0;d:=0.0
 for i:=0;i<m;i+=1{c:=int(v[base+i]);dx:=x[i]-means[c][0];dy:=y[i]-means[c][1];a+=dx*dx;b+=dx*dy;d+=dy*dy};a/=f64(m);b/=f64(m);d/=f64(m);det:=a*d-b*b;if det<=1e-12{return -1};dx:=means[1][0]-means[0][0];dy:=means[1][1]-means[0][1];w0:=(d*dx-b*dy)/det;w1:=(a*dy-b*dx)/det;norm:=math.sqrt(w0*w0+w1*w1);if norm<=1e-12{return -1};w0/=norm;w1/=norm;if w0<0||(math.abs(w0)<=1e-14&&w1<0){w0=-w0;w1=-w1};if out==nil||cap<m{return -2};for i:=0;i<m;i+=1{out[i]=w0*x[i]+w1*y[i]};return i64(m)
}
