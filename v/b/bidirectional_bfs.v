module bidirectional_bfs
const nmax=64
const max_arcs=4096
fn put(out &u8,slot int,v i64){bits:=u64(v);for i in 0..8{unsafe{out[slot*8+i]=u8(bits>>(i*8))}}}
@[export:'bidirectional_bfs']
pub fn bidirectional_bfs(input &i64,length usize,output &u8,capacity usize)i64{
 if isnil(input)||length<4{return -1};nv:=unsafe{input[0]};av:=unsafe{input[1]};sv:=unsafe{input[2]};tv:=unsafe{input[3]};if nv<1||nv>nmax||av<0||av>max_arcs||sv<0||sv>=nv||tv<0||tv>=nv||length!=usize(4+2*av){return -1};n:=int(nv);m:=int(av)
 mut edge:=[nmax][nmax]bool{};mut adj:=[nmax][nmax]int{};mut deg:=[nmax]int{}
 for i in 0..m{u:=unsafe{input[4+2*i]};v:=unsafe{input[5+2*i]};if u<0||u>=nv||v<0||v>=nv{return -1};if !edge[int(u)][int(v)]{edge[int(u)][int(v)]=true;adj[int(u)][deg[int(u)]]=int(v);deg[int(u)]++}}
 for u in 0..n{for v in 0..n{if edge[u][v]!=edge[v][u]{return -1}}}
 start:=int(sv);target:=int(tv);mut path:=[nmax]int{};mut pc:=0
 if start==target{path[pc]=start;pc++}else{mut seen:=[2][nmax]bool{};mut parent:=[2][nmax]int{};for s in 0..2{for i in 0..n{parent[s][i]= -1}};mut q:=[2][nmax]int{};mut head:=[2]int{};mut tail:=[2]int{};seen[0][start]=true;seen[1][target]=true;q[0][0]=start;q[1][0]=target;tail[0]=1;tail[1]=1;mut meet:= -1
  for{if head[0]>=tail[0]||head[1]>=tail[1]{break};end:=tail[0];for head[0]<end{u:=q[0][head[0]];head[0]++;for j in 0..deg[u]{v:=adj[u][j];if seen[0][v]{continue};seen[0][v]=true;parent[0][v]=u;q[0][tail[0]]=v;tail[0]++}};for v in 0..n{if seen[0][v]&&seen[1][v]{meet=v;break}};if meet>=0{break}
   end=tail[1];for head[1]<end{u:=q[1][head[1]];head[1]++;for j in 0..deg[u]{v:=adj[u][j];if seen[1][v]{continue};seen[1][v]=true;parent[1][v]=u;q[1][tail[1]]=v;tail[1]++}};for v in 0..n{if seen[0][v]&&seen[1][v]{meet=v;break}}
  }
  if meet>=0{mut rev:=[nmax]int{};mut k:=0;mut v:=meet;for v!= -1{rev[k]=v;k++;v=parent[0][v]};for k>0{k--;path[pc]=rev[k];pc++};v=parent[1][meet];for v!= -1{path[pc]=v;pc++;v=parent[1][v]}}
 }
 bytes:=(1+pc)*8;if isnil(output)||capacity<usize(bytes){return -2};put(output,0,i64(pc));for i in 0..pc{put(output,1+i,i64(path[i]))};return i64(bytes)
}
