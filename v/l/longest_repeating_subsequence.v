module longest_repeating_subsequence
@[export: 'longest_repeating_subsequence']
pub fn longest_repeating_subsequence(p &i64, n usize) i64 {
 if n<1||n>256{return -1}; size:=unsafe{p[0]};if size<0||size>255||n!=usize(size+1){return -1}
 for k in 0..usize(size){v:=unsafe{p[1+k]};if v<0||v>127{return -1}}
 mut dp:=[256]i64{init:0};for i in 1..usize(size)+1{mut diag:=i64(0);for j in 1..usize(size)+1{above:=dp[j];if unsafe{p[i]}==unsafe{p[j]}&&i!=j{dp[j]=diag+1}else if dp[j-1]>dp[j]{dp[j]=dp[j-1]};diag=above}}return dp[int(size)]
}
