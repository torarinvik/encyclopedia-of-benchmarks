package boruvkas_minimum_spanning_tree
import "core:c"
MAX_N :: 16
root :: proc(p: ^[MAX_N]int, x0: int) -> int { x:=x0;for p[x]!=x {p[x]=p[p[x]];x=p[x]};return x }
@(export)
boruvkas_minimum_spanning_tree :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
 if input==nil||length<2 do return -1
 nv:=input[0];mv:=input[1]
 if nv<2||nv>16||mv<nv-1||mv>64||mv>nv*(nv-1)/2 do return -1
 n:=int(nv);m:=int(mv);if length!=c.size_t(2+3*m) do return -1
 var w:[MAX_N*MAX_N]i64;for i:=0;i<MAX_N*MAX_N;i+=1 {w[i]=i64(9223372036854775807)}
 for k:=0;k<m;k+=1 {u:=input[2+3*k];v:=input[3+3*k];x:=input[4+3*k];if u<1||u>nv||v<1||v>nv||u==v||x<1||x>100||w[(int(u)-1)*MAX_N+int(v)-1]!=i64(9223372036854775807) do return -1;w[(int(u)-1)*MAX_N+int(v)-1]=x;w[(int(v)-1)*MAX_N+int(u)-1]=x}
 var p:[MAX_N]int;for i:=0;i<n;i+=1 {p[i]=i};components:=n;total:i64=0
 for components>1 {var bu,bv:[MAX_N]int;var bw:[MAX_N]i64;for i:=0;i<MAX_N;i+=1 {bu[i]=-1;bv[i]=-1;bw[i]=i64(9223372036854775807)}
  for u:=0;u<n;u+=1 {for v:=u+1;v<n;v+=1 {x:=w[u*MAX_N+v];if x!=i64(9223372036854775807) {a:=root(&p,u);b:=root(&p,v);if a!=b {if x<bw[a] {bw[a]=x;bu[a]=u;bv[a]=v};if x<bw[b] {bw[b]=x;bu[b]=u;bv[b]=v}}}}}
  merged:=false;for r:=0;r<n;r+=1 {if bu[r]>=0 {a:=root(&p,bu[r]);b:=root(&p,bv[r]);if a!=b {p[a]=b;components-=1;total+=bw[r];merged=true}}};if !merged do return -1
 }
 return total
}
