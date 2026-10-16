package median_two_array
import "core:c"
@(export)
median_two_array :: proc "c" (a:[^]i64,length:c.size_t)->f64 {
 bad:f64=-1.0e300
 if a==nil||length<2||length>259||a[0]<0||a[1]<0||a[0]+a[1]<1||a[0]+a[1]>256||int(length)!=int(a[0]+a[1])+2 do return bad
 n:=int(a[0]+a[1]);n1:=int(a[0]);vals:[256]i64
 for i:=0;i<n;i+=1 {vals[i]=a[i+2];if vals[i]<-1000000||vals[i]>1000000 do return bad;if i<n1&&i>0&&vals[i]<vals[i-1] do return bad;if i>=n1&&i>n1&&vals[i]<vals[i-1] do return bad}
 for i:=1;i<n;i+=1{x:=vals[i];j:=i;for j>0&&vals[j-1]>x{vals[j]=vals[j-1];j-=1};vals[j]=x}
 m:=n/2;if n%2==1{return f64(vals[m])};return (f64(vals[m-1])+f64(vals[m]))/2.0
}
