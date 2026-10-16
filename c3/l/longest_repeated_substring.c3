module longest_repeated_substring;
fn long longest_repeated_substring(long* p, usz n) @export("longest_repeated_substring") {
 if(p==null||n<1||n>128||p[0]<0||p[0]>127||n!=(usz)(p[0]+1))return -1;long z=p[0];for(usz k=0;k<(usz)z;k++)if(p[k+1]<0||p[k+1]>127)return -1;long[128][128] dp;for(usz a=0;a<128;a++)for(usz b=0;b<128;b++)dp[a][b]=0;long best=0;usz i=(usz)z;while(i>0){i--;usz j=(usz)z;while(j>i+1){j--;if(p[i+1]==p[j+1]){dp[i][j]=1+dp[i+1][j+1];if(dp[i][j]>best)best=dp[i][j];}}}return best;
}
