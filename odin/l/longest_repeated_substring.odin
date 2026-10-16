package longest_repeated_substring
import "core:c"
@(export)
longest_repeated_substring :: proc "c" (p:[^]i64,n:c.size_t)->i64{if p==nil||n<1||n>128 do return -1;z:=p[0];if z<0||z>127||n!=c.size_t(z+1) do return -1;for k:=c.size_t(0);k<c.size_t(z);k+=1{if p[k+1]<0||p[k+1]>127 do return -1};dp:[128][128]i64;best:=i64(0);for ii:=0;ii<int(z);ii+=1{i:=int(z)-1-ii;for jj:=0;jj<int(z)-i-1;jj+=1{j:=int(z)-1-jj;if p[c.size_t(i+1)]==p[c.size_t(j+1)]{dp[i][j]=1+dp[i+1][j+1];if dp[i][j]>best{best=dp[i][j]}}}};return best}
