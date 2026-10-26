package k_median_p1_local_search
import "core:c"
put64 :: proc(o:[^]u8,at:int,x:i64){b:=u64(x);for i:=0;i<8;i+=1{o[at+i]=u8(b&255);b>>=8}}
objective :: proc(d:[^]i64,n:int,c:[^]i32,k:int)->i64{total:=i64(0);for i:=0;i<n;i+=1{best:=i64(9223372036854775807);for j:=0;j<k;j+=1{if d[i*12+int(c[j])]<best{best=d[i*12+int(c[j])]}};total+=best};return total}
sort_centers :: proc(c:[^]i32,k:int){for i:=1;i<k;i+=1{x:=c[i];j:=i;for j>0&&c[j-1]>x{c[j]=c[j-1];j-=1};c[j]=x}}
lexless :: proc(a:[^]i32,b:[^]i32,k:int)->bool{for i:=0;i<k;i+=1{if a[i]!=b[i]{return a[i]<b[i]}};return false}
@(export)
k_median_p1_local_search :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
 if input==nil||length<2||length>150 do return -1;n0,k0:=input[0],input[1];if n0<2||n0>12||k0<1||k0>4||k0>n0||length!=c.size_t(2+n0*n0+k0) do return -1;n,k:=int(n0),int(k0);d:[144]i64; p:=2
 for i:=0;i<n;i+=1{for j:=0;j<n;j+=1{x:=input[p];p+=1;if x<0||x>1000 do return -1;d[i*12+j]=x}}
 for i:=0;i<n;i+=1{for j:=0;j<n;j+=1{x:=d[i*12+j];if x!=(if i==j{i64(0)}else{x})||x!=d[j*12+i]||(i!=j&&x==0) do return -1;for h:=0;h<n;h+=1{if x>d[i*12+h]+d[h*12+j] do return -1}}}
 selected:[12]bool;centers:[4]i32;for j:=0;j<k;j+=1{x:=input[p];p+=1;if x<0||x>=n0||selected[int(x)] do return -1;centers[j]=i32(x);selected[int(x)]=true};sort_centers(&centers[0],k);current:=objective(&d[0],n,&centers[0],k)
 for{best:=current;bestc:=centers;have:=false;for leave:=0;leave<k;leave+=1{for enter:=0;enter<n;enter+=1{if selected[enter]continue;cand:=centers;cand[leave]=i32(enter);sort_centers(&cand[0],k);value:=objective(&d[0],n,&cand[0],k);if value<current&&(value<best||(value==best&&(!have||lexless(&cand[0],&bestc[0],k)))){best=value;bestc=cand;have=true}}};if !have break;for i:=0;i<k;i+=1{selected[int(centers[i])]=false};centers=bestc;for i:=0;i<k;i+=1{selected[int(centers[i])]=true};current=best}
 bytes:=8*(2+k);if output==nil||capacity<c.size_t(bytes) do return -2;put64(output,0,current);put64(output,8,i64(k));for i:=0;i<k;i+=1{put64(output,16+8*i,i64(centers[i]))};return i64(bytes)
}
