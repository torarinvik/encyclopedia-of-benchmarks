module optimal_binary_search_tree;
fn long optimal_binary_search_tree(long*v,usz n) @export("optimal_binary_search_tree") {
 if(v==null||n<2||n>33||v[0]<1||v[0]>32||n!=(usz)v[0]+1)return -1;usz k=(usz)v[0];long[33] prefix;long[32][32] dp;
 for(usz i=0;i<k;i++){long f=v[i+1];if(f<0||f>1000)return -1;prefix[i+1]=prefix[i]+f;dp[i][i]=f;}
 for(usz w=2;w<=k;w++)for(usz s=0;s+w<=k;s++){usz e=s+w-1;long total=prefix[e+1]-prefix[s],best=1000000000;for(usz r=s;r<=e;r++){long cost=total;if(r>s)cost+=dp[s][r-1];if(r<e)cost+=dp[r+1][e];if(cost<best)best=cost;}dp[s][e]=best;}return dp[0][k-1];
}
