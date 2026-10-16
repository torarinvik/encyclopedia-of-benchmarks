module maximal_square;
fn long maximal_square(long* a, usz len) @export("maximal_square") {
 if(a==null||len<3||len>258||a[0]<1||a[0]>16||a[1]<1||a[1]>16||(usz)(a[0]*a[1])+2!=len)return -1;
 usz rows=(usz)a[0],cols=(usz)a[1]; long dp[16]={}; usz best=0;
 for(usz i=0;i<rows*cols;i++)if(a[i+2]!=0&&a[i+2]!=1)return -1;
 for(usz r=0;r<rows;r++){usz diag=0;for(usz c=0;c<cols;c++){usz above=(usz)dp[c];if(a[r*cols+c+2]==1){if(r==0||c==0)dp[c]=1;else{usz m=diag;if((usz)dp[c]<m)m=(usz)dp[c];if((usz)dp[c-1]<m)m=(usz)dp[c-1];dp[c]=(long)(m+1);}if((usz)dp[c]>best)best=(usz)dp[c];}else dp[c]=0;diag=above;}}
 return (long)(best*best);
}
