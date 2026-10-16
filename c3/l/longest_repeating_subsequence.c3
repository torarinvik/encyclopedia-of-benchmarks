module longest_repeating_subsequence;
fn long longest_repeating_subsequence(long* p, usz n) @export("longest_repeating_subsequence") {
 if(p==null||n<1||n>256||p[0]<0||p[0]>255||n!=(usz)(p[0]+1))return -1;
 long size=p[0];for(usz k=0;k<(usz)size;k++)if(p[1+k]<0||p[1+k]>127)return -1;
 long[256] dp;for(usz k=0;k<256;k++)dp[k]=0;
 for(usz i=1;i<=(usz)size;i++){long diag=0;for(usz j=1;j<=(usz)size;j++){long above=dp[j];if(p[i]==p[j]&&i!=j)dp[j]=diag+1;else if(dp[j-1]>dp[j])dp[j]=dp[j-1];diag=above;}}return dp[(usz)size];
}
