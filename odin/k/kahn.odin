package kahn
import "core:c"
@(export)
kahn :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<2||n>258 do return -2;nv:=v[0];ne:=v[1];if nv<0||nv>32||ne<0||ne>128||n!=c.size_t(2+2*ne) do return -2;adj:[32][32]bool;ind:[32]int;queue:[32]int;for i:=0;i<int(ne);i+=1{a:=v[2+c.size_t(2*i)];b:=v[3+c.size_t(2*i)];if a<0||a>=nv||b<0||b>=nv do return -2;if !adj[a][b]{adj[a][b]=true;ind[b]+=1}};head:=0;tail:=0;for i:=0;i<int(nv);i+=1{if ind[i]==0{queue[tail]=i;tail+=1}};for head<tail{x:=queue[head];head+=1;for y:=0;y<int(nv);y+=1{if adj[x][y]{ind[y]-=1;if ind[y]==0{queue[tail]=y;tail+=1}}}};if tail==int(nv){return nv};return -1}
