package concave_gap_alignment_global
import "core:c"
INF :: i64(1152921504606846976)
put64 :: proc(o:[^]u8,x:i64){b:=u64(x);for j:=0;j<8;j+=1{o[j]=u8(b&255);b>>=8}}
@(export)
concave_gap_alignment_global :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<5||length>26 do return -1;nr:=input[0];mr:=input[1];if nr<1||nr>8||mr<1||mr>8 do return -1;n:=int(nr);m:=int(mr);g:=n;if m>g{g=m};if length!=c.size_t(2+n+m+g) do return -1
 x:[8]i64;y:[8]i64;w:[8]i64;p:=2
 for i:=0;i<n;i+=1{x[i]=input[p];p+=1;if x[i]<0||x[i]>3 do return -1};for j:=0;j<m;j+=1{y[j]=input[p];p+=1;if y[j]<0||y[j]>3 do return -1}
 slope:=INF;for k:=0;k<g;k+=1{w[k]=input[p];p+=1;if w[k]<0||w[k]>100 do return -1;delta:=w[k];if k>0{delta-=w[k-1];if w[k]<w[k-1]||delta>slope do return -1};slope=delta};if output==nil||capacity<8 do return -2
 dp:[81]i64;for i:=0;i<81;i+=1{dp[i]=INF};dp[0]=0
 for i:=0;i<=n;i+=1{for j:=0;j<=m;j+=1{if i==0&&j==0{continue};best:=INF;if i>0&&j>0{cost:=dp[(i-1)*9+j-1];if x[i-1]!=y[j-1]{cost+=1};if cost<best{best=cost}};for gap:=1;gap<=i;gap+=1{cost:=dp[(i-gap)*9+j]+w[gap-1];if cost<best{best=cost}};for gap:=1;gap<=j;gap+=1{cost:=dp[i*9+j-gap]+w[gap-1];if cost<best{best=cost}};dp[i*9+j]=best}}
 put64(output,dp[n*9+m]);return 8
}
