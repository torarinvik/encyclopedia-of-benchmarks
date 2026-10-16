module longest_increasing_subsequence_iterative
@[export: 'longest_increasing_subsequence_iterative']
pub fn longest_increasing_subsequence_iterative(v &i64,n usize) i64{if n<1||n>65{return -1};count:=unsafe{v[0]};if count<0||count>64||n!=usize(count+1){return -1};mut dp:=[64]i64{};for i in 0..int(count){x:=unsafe{v[i+1]};if x< -1000000||x>1000000{return -1};dp[i]=1};for i in 0..int(count){for j in 0..i{if unsafe{v[j+1]}<=unsafe{v[i+1]}&&dp[j]+1>dp[i]{dp[i]=dp[j]+1}}};mut best:=i64(0);for i in 0..int(count){if dp[i]>best{best=dp[i]}};return best}
