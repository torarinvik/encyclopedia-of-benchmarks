module dijkstra_positive_connected
fn put_i64_le(mut output &u8,index int,value i64){mut bits:=u64(value);for b in 0..8{unsafe{output[index*8+b]=u8(bits&255)};bits>>=8}}
@[export:'dijkstra_positive_connected']
pub fn dijkstra_positive_connected(input &i64,length usize,mut output &u8,capacity usize)i64{
 if unsafe{input==nil}||length<2{return -1};nv:=input[0];mv:=input[1];if nv<1||nv>4||mv<0||mv>6||length!=usize(2+3*mv){return -1};n:=int(nv);m:=int(mv);if m<n-1||m>n*(n-1)/2{return -1}
 unsafe{mut weight:=[16]i64{};mut adjacent:=[16]bool{};mut neighbors:=[24]int{};mut degree:=[4]int{}
 for e in 0..m{u:=input[2+3*e];v:=input[3+3*e];w:=input[4+3*e];if u<0||u>=nv||v<0||v>=nv||u==v||w<1||w>255{return -1};ui:=int(u);vi:=int(v);uv:=ui*4+vi;vu:=vi*4+ui;if adjacent[uv]{return -1};adjacent[uv]=true;adjacent[vu]=true;weight[uv]=w;weight[vu]=w;neighbors[ui*6+degree[ui]]=vi;degree[ui]++;neighbors[vi*6+degree[vi]]=ui;degree[vi]++}
 mut seen:=[4]bool{};mut stack:=[4]int{};mut top:=1;stack[0]=0;seen[0]=true;for top>0{top--;u:=stack[top];for j in 0..degree[u]{v:=neighbors[u*6+j];if !seen[v]{seen[v]=true;stack[top]=v;top++}}};for v in 0..n{if !seen[v]{return -1}}
 mut dist:=[4]i64{};mut done:=[4]bool{};for v in 0..4{dist[v]=1000000000;done[v]=false};dist[0]=0
 for _ in 0..n{mut selected:=-1;for v in 0..n{if !done[v]&&(selected<0||dist[v]<dist[selected]){selected=v}};if selected<0{break};done[selected]=true;for j in 0..degree[selected]{v:=neighbors[selected*6+j];if !done[v]&&dist[selected]+weight[selected*4+v]<dist[v]{dist[v]=dist[selected]+weight[selected*4+v]}}}
 if output==nil||capacity<n*8{return -2};for v in 0..n{put_i64_le(mut output,v,dist[v])};return i64(n*8)}
}
