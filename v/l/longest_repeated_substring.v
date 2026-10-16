module longest_repeated_substring
@[export: 'longest_repeated_substring']
pub fn longest_repeated_substring(p &i64,n usize)i64{if n<1||n>128{return -1};z:=unsafe{p[0]};if z<0||z>127||n!=usize(z+1){return -1};for k in 0..usize(z){v:=unsafe{p[k+1]};if v<0||v>127{return -1}}mut dp:=[128][128]i64{init:0};mut best:=i64(0);for ii:=0;ii<int(z);ii++{i:=int(z)-1-ii;for jj:=0;jj<int(z)-i-1;jj++{j:=int(z)-1-jj;if unsafe{p[i+1]}==unsafe{p[j+1]}{dp[i][j]=1+dp[i+1][j+1];if dp[i][j]>best{best=dp[i][j]}}}}return best}
