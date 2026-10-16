package longest_increasing_subsequence_iterative
import "core:c"
@(export)
longest_increasing_subsequence_iterative :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<1||n>65 do return -1;count:=v[0];if count<0||count>64||n!=c.size_t(count+1) do return -1;a:[64]i64;dp:[64]i64;for i:=0;i<int(count);i+=1{a[i]=v[1+c.size_t(i)];if a[i]< -1000000||a[i]>1000000 do return -1;dp[i]=1};for i:=0;i<int(count);i+=1{for j:=0;j<i;j+=1{if a[j]<=a[i]&&dp[j]+1>dp[i]{dp[i]=dp[j]+1}}};best:=i64(0);for i:=0;i<int(count);i+=1{if dp[i]>best{best=dp[i]}};return best}
