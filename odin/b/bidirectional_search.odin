package bidirectional_search
import "core:c"
N :: 64
MAX_ARCS :: N*(N-1)
put :: proc "contextless" (out:[^]u8,slot:int,v:i64){b:=u64(v);for i:=0;i<8;i+=1{out[slot*8+i]=u8(b>>u64(i*8))}}
@(export)
bidirectional_search :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<4||input[0]<1||input[0]>N do return -1;n:=int(input[0]);if input[1]<0||input[1]>=i64(n)||input[2]<0||input[2]>=i64(n)||input[3]<0||input[3]>MAX_ARCS||int(length)!=4+2*int(input[3]) do return -1;m:=int(input[3]);adj:[N][N-1]int;deg:[N]int;edge:[N][N]bool
 for i:=0;i<m;i+=1{u:=input[4+2*i];v:=input[5+2*i];if u<0||u>=i64(n)||v<0||v>=i64(n)||u==v||edge[int(u)][int(v)] do return -1;edge[int(u)][int(v)]=true;adj[int(u)][deg[int(u)]]=int(v);deg[int(u)]+=1};for u:=0;u<n;u+=1{for v:=0;v<n;v+=1{if edge[u][v]!=edge[v][u] do return -1}}
 path:[N]int;pc:=0;start:=int(input[1]);goal:=int(input[2]);if start==goal{path[pc]=start;pc+=1}else{parent:[2][N]int;for s:=0;s<2;s+=1{for i:=0;i<n;i+=1{parent[s][i]= -2}};q:[2][N]int;head:[2]int;tail:[2]int;parent[0][start]= -1;parent[1][goal]= -1;q[0][0]=start;q[1][0]=goal;tail[0]=1;tail[1]=1;meet:= -1
  for{if head[0]>=tail[0]||head[1]>=tail[1]||meet>=0 do break;for s:=0;s<2;s+=1{if meet>=0 do break;cur:=q[s][head[s]];head[s]+=1;for j:=0;j<deg[cur];j+=1{v:=adj[cur][j];if parent[s][v]!= -2 do continue;parent[s][v]=cur;q[s][tail[s]]=v;tail[s]+=1;if parent[1-s][v]!= -2{meet=v;break}}}}
  if meet>=0{rev:[N]int;k:=0;for v:=meet;v!= -1;v=parent[0][v]{rev[k]=v;k+=1};for k>0{k-=1;path[pc]=rev[k];pc+=1};for v:=parent[1][meet];v!= -1;v=parent[1][v]{path[pc]=v;pc+=1}}
 }
 bytes:=(1+pc)*8;if output==nil||int(capacity)<bytes do return -2;put(output,0,i64(pc));for i:=0;i<pc;i+=1{put(output,1+i,i64(path[i]))};return i64(bytes)
}
