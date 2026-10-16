export fn optimal_binary_search_tree(v:[*]const i64,n:usize)i64{
 if(n<2 or n>33 or v[0]<1 or v[0]>32 or n!=@as(usize,@intCast(v[0]))+1)return -1;const k:usize=@intCast(v[0]);var prefix=[_]i64{0}**33;var dp=[_] [32]i64{[_]i64{0}**32}**32;
 for(0..k)|i|{const f=v[i+1];if(f<0 or f>1000)return -1;prefix[i+1]=prefix[i]+f;dp[i][i]=f;}
 var width:usize=2;while(width<=k):(width+=1){var start:usize=0;while(start+width<=k):(start+=1){const end=start+width-1;const total=prefix[end+1]-prefix[start];var best:i64=1000000000;for(start..end+1)|root|{var cost=total;if(root>start)cost+=dp[start][root-1];if(root<end)cost+=dp[root+1][end];if(cost<best)best=cost;}dp[start][end]=best;}}
 return dp[0][k-1];
}
