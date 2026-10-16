export fn ones_and_zeros(v:[*]const i64,n:usize)i64{
 if(n<3 or v[0]<0 or v[0]>32 or v[1]<0 or v[1]>32 or v[2]<0 or v[2]>32)return -1;const count:usize=@intCast(v[0]);const zb:usize=@intCast(v[1]);const ob:usize=@intCast(v[2]);if(n!=3+2*count)return -1;
 var dp=[_] [33]i64{[_]i64{0}**33}**33;
 for(0..count)|i|{const z0=v[3+2*i];const o0=v[4+2*i];if(z0<0 or z0>32 or o0<0 or o0>32)return -1;const z:usize=@intCast(z0);const o:usize=@intCast(o0);var a:usize=zb;while(a>=z):(a-=1){var b:usize=ob;while(b>=o):(b-=1){const candidate=dp[a-z][b-o]+1;if(candidate>dp[a][b])dp[a][b]=candidate;if(b==o)break;}if(a==z)break;}}
 return dp[zb][ob];
}
