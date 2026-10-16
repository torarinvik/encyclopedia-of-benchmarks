package longest_repeating_subsequence
import "core:c"
@(export)
longest_repeating_subsequence :: proc "c" (p: [^]i64,n:c.size_t)->i64{
 if p==nil||n<1||n>256 do return -1; size:=p[0];if size<0||size>255||n!=c.size_t(size+1) do return -1
 for k:=c.size_t(0);k<c.size_t(size);k+=1{if p[1+k]<0||p[1+k]>127 do return -1}
 dp:[256]i64;for k:=0;k<256;k+=1{dp[k]=0};for i:=1;i<=int(size);i+=1{diag:=i64(0);for j:=1;j<=int(size);j+=1{above:=dp[j];if p[c.size_t(i)]==p[c.size_t(j)]&&i!=j{dp[j]=diag+1}else if dp[j-1]>dp[j]{dp[j]=dp[j-1]};diag=above}};return dp[int(size)]
}
