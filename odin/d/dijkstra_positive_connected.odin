package dijkstra_positive_connected
import "core:c"
put_i64 :: proc "contextless"(output:[^]u8,index:usize,value:i64){bits:=transmute(u64)value;for b:=0;b<8;b+=1{output[index*8+b]=u8(bits>>u64(8*b))}}
@(export)
dijkstra_positive_connected :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<2 do return -1
 nv,mv:=input[0],input[1];if nv<1||nv>4||mv<0||mv>6||length!=usize(2+3*mv) do return -1;n,m:=usize(nv),usize(mv);if m<n-1||m>n*(n-1)/2 do return -1
 weight:[16]i64;adj:[16]bool;neighbors:[24]usize;degree:[4]usize
 for e:usize=0;e<m;e+=1{u,v,w:=input[2+3*e],input[3+3*e],input[4+3*e];if u<0||u>=nv||v<0||v>=nv||u==v||w<1||w>255 do return -1;ui,vi:=usize(u),usize(v);uv,vu:=ui*4+vi,vi*4+ui;if adj[uv] do return -1;adj[uv]=true;adj[vu]=true;weight[uv]=w;weight[vu]=w;neighbors[ui*6+degree[ui]]=vi;degree[ui]+=1;neighbors[vi*6+degree[vi]]=ui;degree[vi]+=1}
 seen:[4]bool;stack:[4]usize;top:usize=1;stack[0]=0;seen[0]=true;for top>0{top-=1;u:=stack[top];for j:usize=0;j<degree[u];j+=1{v:=neighbors[u*6+j];if !seen[v]{seen[v]=true;stack[top]=v;top+=1}}};for v:usize=0;v<n;v+=1{if !seen[v] do return -1}
 dist:[4]i64;done:[4]bool;for v:usize=0;v<4;v+=1{dist[v]=1000000000;done[v]=false};dist[0]=0;for step:usize=0;step<n;step+=1{selected:=i64(-1);for v:usize=0;v<n;v+=1{if !done[v]&&(selected<0||dist[v]<dist[usize(selected)]){selected=i64(v)}};if selected<0 do break;u:=usize(selected);done[u]=true;for j:usize=0;j<degree[u];j+=1{v:=neighbors[u*6+j];if !done[v]&&dist[u]+weight[u*4+v]<dist[v]{dist[v]=dist[u]+weight[u*4+v]}}}
 if output==nil||capacity<n*8 do return -2;for v:usize=0;v<n;v+=1{put_i64(output,v,dist[v])};return i64(n*8)
}
