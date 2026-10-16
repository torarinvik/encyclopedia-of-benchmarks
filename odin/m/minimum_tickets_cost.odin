package minimum_tickets_cost
import "core:c"
@(export)
minimum_tickets_cost :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<4||n>369||v[0]<0||v[0]>365 do return -1;d:=int(v[0]);if n!=c.size_t(d+4) do return -1;travel:[366]bool;for i:=0;i<d;i+=1{x:=v[i+1];if x<1||x>365||travel[int(x)] do return -1;travel[int(x)]=true};c0:=v[d+1];c1:=v[d+2];c2:=v[d+3];if c0<0||c0>1000000||c1<0||c1>1000000||c2<0||c2>1000000 do return -1;dp:[397]i64;for day:=365;day>=1;day-=1{dp[day]=dp[day+1];if travel[day]{a:=c0+dp[day+1];b:=c1+dp[day+7];z:=c2+dp[day+30];if b<a do a=b;if z<a do a=z;dp[day]=a}};return dp[1]}
