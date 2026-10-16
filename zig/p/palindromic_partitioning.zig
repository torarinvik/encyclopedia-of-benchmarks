export fn palindromic_partitioning(v:[*c]const i64,n:usize)i64{
 if(v==null or n<2 or n>65 or v[0]<1 or v[0]>64 or n!=@as(usize,@intCast(v[0]))+1)return -1;
 const m:usize=@intCast(v[0]);var p=[_] [64]bool{[_]bool{false}**64}**64;var cuts=[_]i64{0}**64;
 for(0..m)|end|{if(v[end+1]<0 or v[end+1]>127)return -1;for(0..end+1)|start|{p[start][end]=v[start+1]==v[end+1] and (end-start<2 or p[start+1][end-1]);}}
 for(0..m)|end|{if(p[0][end]){cuts[end]=0}else{cuts[end]=64;for(1..end+1)|start|{if(p[start][end] and cuts[start-1]+1<cuts[end])cuts[end]=cuts[start-1]+1;}}}
 return cuts[m-1];
}
