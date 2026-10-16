module eulerian_trail_undirected_simple
const max_v=10
const max_e=45
fn dfs(u int, neighbors [max_v][max_e]int, degree [max_v]int, mut seen [max_v][max_v]bool, mut path [max_e+1]i64, mut count int){path[count]=i64(u);count++;for i in 0..degree[u]{v:=neighbors[u][i];if !seen[u][v]{seen[u][v]=true;seen[v][u]=true;dfs(v,neighbors,degree,mut seen,mut path,mut count)}}}
fn put(out &u8,slot int,value i64){bits:=u64(value);for i in 0..8{unsafe{out[slot*8+i]=u8(bits>>(i*8))}}}
@[export:'eulerian_trail_undirected_simple']
pub fn eulerian_trail_undirected_simple(input &i64,length usize,output &u8,capacity usize)i64{
 if isnil(input)||length<2{return -1};n64:=unsafe{input};m64:=unsafe{input[1]};if n64<2||n64>max_v||m64<0||m64>max_e{return -1};n:=int(n64);m:=int(m64);if length!=usize(2+2*m){return -1}
 mut neighbors:=[max_v][max_e]int{};mut degree:=[max_v]int{};mut adjacent:=[max_v][max_v]bool{}
 for i in 0..m{a:=unsafe{input[2+2*i]};b:=unsafe{input[3+2*i]};if a<0||b<0||a>=n64||b>=n64||a==b{return -1};u:=int(a);v:=int(b);if adjacent[u][v]{return -1};adjacent[u][v]=true;adjacent[v][u]=true;neighbors[u][degree[u]]=v;degree[u]++;neighbors[v][degree[v]]=u;degree[v]++}
 mut odd:=0;mut start:=1;for v in 0..n{if degree[v]%2==1{odd++;start=v}};if odd!=0&&odd!=2{return -1};mut status:=i64(2);if odd==0{status=1;start=1}
 if m>0{if status==1&&degree[1]==0{return -1};mut reached:=[max_v]bool{};mut stack:=[max_v]int{};mut top:=0;stack[top]=start;top++;reached[start]=true;for top>0{top--;u:=stack[top];for i in 0..degree[u]{v:=neighbors[u][i];if !reached[v]{reached[v]=true;stack[top]=v;top++}}};for v in 0..n{if degree[v]>0&&!reached[v]{return -1}}}
 mut seen:=[max_v][max_v]bool{};mut path:=[max_e+1]i64{};mut count:=0;dfs(start,neighbors,degree,mut seen,mut path,mut count);if count!=m+1{return -1};bytes:=(2+count)*8;if isnil(output)||capacity<usize(bytes){return -2};put(output,0,status);put(output,1,i64(count));for i in 0..count{put(output,2+i,path[i])};return i64(bytes)
}
