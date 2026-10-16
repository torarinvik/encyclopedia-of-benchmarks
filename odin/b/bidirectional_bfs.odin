package bidirectional_bfs
import "core:c"
N :: 64
MAX_ARCS :: 4096
put :: proc "contextless" (out:[^]u8,slot:int,v:i64){b:=u64(v);for i:=0;i<8;i+=1{out[slot*8+i]=u8(b>>u64(i*8))}}
@(export)
bidirectional_bfs :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<4 do return -1
 nv:=input[0];av:=input[1];sv:=input[2];tv:=input[3];if nv<1||nv>N||av<0||av>MAX_ARCS||sv<0||sv>=nv||tv<0||tv>=nv||int(length)!=4+2*int(av) do return -1;n:=int(nv);m:=int(av)
 edge:[N][N]bool;adj:[N][N]int;deg:[N]int
 for i:=0;i<m;i+=1{u:=input[4+2*i];v:=input[5+2*i];if u<0||u>=nv||v<0||v>=nv do return -1;if !edge[int(u)][int(v)]{edge[int(u)][int(v)]=true;adj[int(u)][deg[int(u)]]=int(v);deg[int(u)]+=1}}
 for u:=0;u<n;u+=1{for v:=0;v<n;v+=1{if edge[u][v]!=edge[v][u] do return -1}}
 start:=int(sv);target:=int(tv);path:[N]int;pc:=0
 if start==target{path[pc]=start;pc+=1}else{seen:[2][N]bool;parent:[2][N]int;for s:=0;s<2;s+=1{for i:=0;i<n;i+=1{parent[s][i]= -1}};q:[2][N]int;head:[2]int;tail:[2]int;seen[0][start]=true;seen[1][target]=true;q[0][0]=start;q[1][0]=target;tail[0]=1;tail[1]=1;meet:= -1
  for{if head[0]>=tail[0]||head[1]>=tail[1] do break;end:=tail[0];for head[0]<end{u:=q[0][head[0]];head[0]+=1;for j:=0;j<deg[u];j+=1{v:=adj[u][j];if seen[0][v] do continue;seen[0][v]=true;parent[0][v]=u;q[0][tail[0]]=v;tail[0]+=1}};for v:=0;v<n;v+=1{if seen[0][v]&&seen[1][v]{meet=v;break}};if meet>=0 do break
   end=tail[1];for head[1]<end{u:=q[1][head[1]];head[1]+=1;for j:=0;j<deg[u];j+=1{v:=adj[u][j];if seen[1][v] do continue;seen[1][v]=true;parent[1][v]=u;q[1][tail[1]]=v;tail[1]+=1}};for v:=0;v<n;v+=1{if seen[0][v]&&seen[1][v]{meet=v;break}}
  }
  if meet>=0{rev:[N]int;k:=0;for v:=meet;v!= -1;v=parent[0][v]{rev[k]=v;k+=1};for k>0{k-=1;path[pc]=rev[k];pc+=1};for v:=parent[1][meet];v!= -1;v=parent[1][v]{path[pc]=v;pc+=1}}
 }
 bytes:=(1+pc)*8;if output==nil||int(capacity)<bytes do return -2;put(output,0,i64(pc));for i:=0;i<pc;i+=1{put(output,1+i,i64(path[i]))};return i64(bytes)
}
