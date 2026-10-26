module treewidth_min_fill_elimination
const max_n=16
const max_edges=120
const max_input=242
const max_output=2064
fn put_i64(mut output &u8,offset int,value i64){bits:=u64(value);for byte in 0..8{unsafe{output[offset+byte]=u8((bits>>(8*byte))&255)}}}
@[export:'treewidth_min_fill_elimination']
pub fn treewidth_min_fill_elimination(input &i64,length usize,mut output &u8,capacity usize)i64{unsafe{
 if input==nil||length<2||length>max_input||input[0]<1||input[0]>max_n||input[1]<0||input[1]>max_edges{return -1};n,m:=int(input[0]),int(input[1]);if m>n*(n-1)/2||length!=usize(2+2*m){return -1}
 mut adjacent:=[max_n][max_n]bool{};for edge in 0..m{a64,b64:=input[2+2*edge],input[3+2*edge];if a64<0||b64<0||a64>=i64(n)||b64>=i64(n)||a64>=b64{return -1};a,b:=int(a64),int(b64);if adjacent[a][b]{return -1};adjacent[a][b]=true;adjacent[b][a]=true}
 mut active:=[max_n]bool{};for i in 0..n{active[i]=true};mut order:=[max_n]i64{};mut fill_u:=[max_edges]i64{};mut fill_v:=[max_edges]i64{};mut width:=0;mut fill_count:=0
 for step in 0..n{mut chosen:=-1;mut chosen_fill:=max_edges+1;mut chosen_degree:=0;for vertex in 0..n{if active[vertex]{mut neighbors:=[max_n]int{};mut count:=0;for other in 0..n{if active[other]&&adjacent[vertex][other]{neighbors[count]=other;count++}};mut missing:=0;for i in 0..count{for j in i+1..count{if !adjacent[neighbors[i]][neighbors[j]]{missing++}}};if missing<chosen_fill{chosen=vertex;chosen_fill=missing;chosen_degree=count}}};order[step]=i64(chosen);if chosen_degree>width{width=chosen_degree};mut neighbors:=[max_n]int{};mut count:=0;for other in 0..n{if active[other]&&adjacent[chosen][other]{neighbors[count]=other;count++}};for i in 0..count{for j in i+1..count{a,b:=neighbors[i],neighbors[j];if !adjacent[a][b]{adjacent[a][b]=true;adjacent[b][a]=true;fill_u[fill_count]=i64(a);fill_v[fill_count]=i64(b);fill_count++}}};active[chosen]=false}
 bytes:=8*(n+2+2*fill_count);if output==nil||capacity<usize(bytes)||bytes>max_output{return -2};mut staged:=[max_output]u8{};put_i64(mut &staged[0],0,i64(width));for i in 0..n{put_i64(mut &staged[0],8*(i+1),order[i])};put_i64(mut &staged[0],8*(n+1),i64(fill_count));for i in 0..fill_count{put_i64(mut &staged[0],8*(n+2+2*i),fill_u[i]);put_i64(mut &staged[0],8*(n+3+2*i),fill_v[i])};for i in 0..bytes{output[i]=staged[i]};return i64(bytes)
}}
