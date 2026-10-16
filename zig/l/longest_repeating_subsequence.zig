export fn longest_repeating_subsequence(p: [*]const i64, n: usize) i64 {
 if(n<1 or n>256)return -1;const size=p[0];if(size<0 or size>255 or n!=@as(usize,@intCast(size))+1)return -1;
 for(0..@as(usize,@intCast(size)))|k|{if(p[1+k]<0 or p[1+k]>127)return -1;}
 var dp:[256]i64=@splat(0);for(1..@as(usize,@intCast(size))+1)|i|{var diag:i64=0;for(1..@as(usize,@intCast(size))+1)|j|{const above=dp[j];if(p[i]==p[j] and i!=j){dp[j]=diag+1;}else if(dp[j-1]>dp[j]){dp[j]=dp[j-1];}diag=above;}}return dp[@intCast(size)];
}
