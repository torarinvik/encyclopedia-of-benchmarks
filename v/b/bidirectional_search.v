module bidirectional_search
const nmax=64
const max_arcs=nmax*(nmax-1)
fn put(out &u8,slot int,v i64){bits:=u64(v);for i in 0..8{unsafe{out[slot*8+i]=u8(bits>>(i*8))}}}
@[export:'bidirectional_search']
pub fn bidirectional_search(input &i64,length usize,output &u8,capacity usize)i64{
 if isnil(input)||length<4{return -1};nn:=unsafe{input[0]};if nn<1||nn>nmax{return -1};n:=int(nn);a:=unsafe{input[1]};b:=unsafe{input[2]};mm:=unsafe{input[3]};if a<0||a>=nn||b<0||b>=nn||mm<0||mm>max_arcs||length!=usize(4+2*mm){return -1};m:=int(mm)
 mut adj:=[nmax][nmax-1]int{};mut deg:=[nmax]int{};mut edge:=[nmax][nmax]bool{}
 for i in 0..m{u:=unsafe{input[4+2*i]};v:=unsafe{input[5+2*i]};if u<0||u>=nn||v<0||v>=nn||u==v||edge[int(u)][int(v)]{return -1};edge[int(u)][int(v)]=true;adj[int(u)][deg[int(u)]]=int(v);deg[int(u)]++};for u in 0..n{for v in 0..n{if edge[u][v]!=edge[v][u]{return -1}}}
 mut path:=[nmax]int{};mut pc:=0;start:=int(a);goal:=int(b)
 if start==goal{path[pc]=start;pc++}else{mut parent:=[2][nmax]int{};for s in 0..2{for i in 0..n{parent[s][i]= -2}};mut q:=[2][nmax]int{};mut head:=[2]int{};mut tail:=[2]int{};parent[0][start]= -1;parent[1][goal]= -1;q[0][0]=start;q[1][0]=goal;tail[0]=1;tail[1]=1;mut meet:= -1
  for{if head[0]>=tail[0]||head[1]>=tail[1]||meet>=0{break};for s in 0..2{if meet>=0{break};cur:=q[s][head[s]];head[s]++;for j in 0..deg[cur]{v:=adj[cur][j];if parent[s][v]!= -2{continue};parent[s][v]=cur;q[s][tail[s]]=v;tail[s]++;if parent[1-s][v]!= -2{meet=v;break}}}}
  if meet>=0{mut rev:=[nmax]int{};mut k:=0;mut v:=meet;for v!= -1{rev[k]=v;k++;v=parent[0][v]};for k>0{k--;path[pc]=rev[k];pc++};v=parent[1][meet];for v!= -1{path[pc]=v;pc++;v=parent[1][v]}}
 }
 bytes:=(1+pc)*8;if isnil(output)||capacity<usize(bytes){return -2};put(output,0,i64(pc));for i in 0..pc{put(output,1+i,i64(path[i]))};return i64(bytes)
}
