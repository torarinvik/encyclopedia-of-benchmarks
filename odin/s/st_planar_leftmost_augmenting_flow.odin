package st_planar_leftmost_augmenting_flow
import "core:c"
N :: 6
M :: 10
MAX_INPUT :: 60
put_i64 :: proc "contextless" (output:[^]u8,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{output[b]=u8((bits>>(8*b))&255)}}
@(export)
st_planar_leftmost_augmenting_flow :: proc "c" (input:[^]i64,input_length:c.size_t,output:[^]u8,output_capacity:c.size_t)->i64 {
 if input==nil||input_length<4||input_length>MAX_INPUT do return -1
 n0,m0,s0,t0:=input[0],input[1],input[2],input[3]
 if n0<2||n0>N||m0<1||m0>M||s0<0||s0>=n0||t0<0||t0>=n0||s0==t0 do return -1
 n,m,s,t:=int(n0),int(m0),int(s0),int(t0);if input_length<c.size_t(4+3*m) do return -1
 eu,ev,caps:[M]int={};pairs:[N][N]bool={};at:=4
 for e:=0;e<m;e+=1{u,v,c0:=input[at],input[at+1],input[at+2];at+=3;if u<0||u>=n0||v<0||v>=n0||u==v||c0<0||c0>5 do return -1;if pairs[int(u)][int(v)]||pairs[int(v)][int(u)] do return -1;pairs[int(u)][int(v)]=true;pairs[int(v)][int(u)]=true;eu[e],ev[e],caps[e]=int(u),int(v),int(c0)}
 deg:[N]int={};rot:[N][N]int={};occ:[M][2]int={};rot_seen:[N][M]bool={}
 for x:=0;x<n;x+=1{if at>=int(input_length) do return -1;d:=input[at];at+=1;if d<0||d>=n||at+int(d)>int(input_length) do return -1;deg[x]=int(d);for j:=0;j<deg[x];j+=1{e0:=input[at];at+=1;if e0<0||e0>=m0 do return -1;e:=int(e0);if rot_seen[x][e] do return -1;rot_seen[x][e]=true;rot[x][j]=e;if eu[e]==x{occ[e][0]+=1}else if ev[e]==x{occ[e][1]+=1}else{return -1}}}
 if at!=int(input_length) do return -1;for e:=0;e<m;e+=1{if occ[e][0]!=1||occ[e][1]!=1 do return -1}
 conn:[N]bool={};q:[N]int={};head,tail:=0,0;conn[s]=true;q[tail]=s;tail+=1
 for head<tail{x:=q[head];head+=1;for e:=0;e<m;e+=1{y:=-1;if eu[e]==x{y=ev[e]}else if ev[e]==x{y=eu[e]};if y>=0&&!conn[y]{conn[y]=true;q[tail]=y;tail+=1}}};for x:=0;x<n;x+=1{if !conn[x] do return -1}
 flow:[M]int={};total:=0
 for {vis:[N]bool={};parent,pe,pdir,next:[N]int={};for x:=0;x<n;x+=1{parent[x]=-1;pe[x]=-1};stack:[N]int={};top:=0;vis[s]=true;stack[top]=s;top+=1
  for top>0&&!vis[t]{x:=stack[top-1];if next[x]>=deg[x]{top-=1;continue};e:=rot[x][next[x]];next[x]+=1;y:=eu[e];rem:=flow[e];dir:=-1;if eu[e]==x{y=ev[e];rem=caps[e]-flow[e];dir=1};if rem>0&&!vis[y]{vis[y]=true;parent[y],pe[y],pdir[y]=x,e,dir;stack[top]=y;top+=1}}
  if !vis[t]{break};delta:=1000000;y:=t;for y!=s{x:=parent[y];e:=pe[y];r:=flow[e];if eu[e]==x{r=caps[e]-flow[e]};if r<delta{delta=r};y=x};y=t;for y!=s{e:=pe[y];flow[e]+=pdir[y]*delta;y=parent[y]};total+=delta
 }
 if output==nil||output_capacity<8 do return -2;put_i64(output,i64(total));return 8
}
