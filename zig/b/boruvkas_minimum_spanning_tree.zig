const MAX_N:usize=16;
fn root(p:*[MAX_N]usize,x0:usize)usize{var x=x0;while(p[x]!=x){p[x]=p[p[x]];x=p[x];}return x;}
/// Return the total weight of a connected undirected graph's MST.
export fn boruvkas_minimum_spanning_tree(input:[*]const i64,length:usize)i64{
 if(length<2)return -1;const a=input[0..length];const nv=a[0];const mv=a[1];if(nv<2 or nv>16 or mv<nv-1 or mv>64 or mv>nv*(nv-1)/2)return -1;
 const n:usize=@intCast(nv);const m:usize=@intCast(mv);if(length!=2+3*m)return -1;var w=[_][MAX_N]i64{[_]i64{std.math.maxInt(i64)}**MAX_N}**MAX_N;
 for(0..m)|k|{const u=a[2+3*k];const v=a[3+3*k];const x=a[4+3*k];if(u<1 or u>nv or v<1 or v>nv or u==v or x<1 or x>100 or w[@intCast(u-1)][@intCast(v-1)]!=std.math.maxInt(i64))return -1;w[@intCast(u-1)][@intCast(v-1)]=x;w[@intCast(v-1)][@intCast(u-1)]=x;}
 var p=[_]usize{0}**MAX_N;for(0..n)|i|p[i]=i;var components=n;var total:i64=0;
 while(components>1){var bu=[_]isize{-1}**MAX_N;var bv=[_]isize{-1}**MAX_N;var bw=[_]i64{std.math.maxInt(i64)}**MAX_N;
  for(0..n)|u|{for(u+1..n)|v|{const x=w[u][v];if(x!=std.math.maxInt(i64)){const aa=root(&p,u);const bb=root(&p,v);if(aa!=bb){if(x<bw[aa]){bw[aa]=x;bu[aa]=@intCast(u);bv[aa]=@intCast(v);}if(x<bw[bb]){bw[bb]=x;bu[bb]=@intCast(u);bv[bb]=@intCast(v);}}}}}
  var merged=false;for(0..n)|r|{if(bu[r]>=0){const aa=root(&p,@intCast(bu[r]));const bb=root(&p,@intCast(bv[r]));if(aa!=bb){p[aa]=bb;components-=1;total+=bw[r];merged=true;}}}if(!merged)return -1;
 }return total;
}
const std=@import("std");
