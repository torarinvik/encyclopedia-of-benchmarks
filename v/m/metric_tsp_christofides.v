module metric_tsp_christofides

@[export: 'metric_tsp_christofides']
pub fn metric_tsp_christofides(input &i64, length usize, output &u8, capacity usize) i64 {
 unsafe {
  if input==nil||length<2||length>65{return -1};n64:=input[0];if n64<1||n64>8||length!=usize(1+n64*n64){return -1};n:=int(n64)
  mut d:=[][]i64{};for _ in 0..8{d<<[]i64{len:8,init:0}}
  for i in 0..n{for j in 0..n{w:=input[1+i*n+j];if w<0||w>10000||(i==j&&w!=0){return -1};d[i][j]=w}}
  for i in 0..n{for j in 0..n{if d[i][j]!=d[j][i]{return -1};for k in 0..n{if d[i][j]>d[i][k]+d[k][j]{return -1}}}}
  bytes:=8*(n+2);if output==nil||capacity<usize(bytes){return -2}
  mut edges:=[]tuple[int,int,int]{};for i in 0..n{for j in i+1..n{edges<<tuple{d[i][j],i,j}}};edges.sort(a,b){if a.0!=b.0{return a.0<b.0};if a.1!=b.1{return a.1<b.1};return a.2<b.2}
  mut parent:=[]int{len:n,init:0};for i in 0..n{parent[i]=i};mut tree:=[][]bool{};for _ in 0..8{tree<<[]bool{len:8,init:false}}
  mut accepted:=0;for edge in edges{mut a,b:=edge.1,edge.2;for parent[a]!=a{a=parent[a]};for parent[b]!=b{b=parent[b]};if a!=b{parent[b]=a;tree[edge.1][edge.2]=true;tree[edge.2][edge.1]=true;accepted++};if accepted==n-1{break}}
  mut odd:=[]int{};for i in 0..n{mut deg:=0;for j in 0..n{if tree[i][j]{deg++}};if deg%2==1{odd<<i}}
  full:=(1<<odd.len)-1;mut dp:=[]i64{len:256,init:0};mut pick:=[]int{len:256,init:-1};for i in 0..256{dp[i]=i64(9223372036854775807/4)}
  for mask in 1..full+1{mut i:=0;for (mask&(1<<i))==0{i++};rest:=mask^(1<<i);for j in i+1..odd.len{if (rest&(1<<j))!=0{tail:=rest^(1<<j);val:=dp[tail]+d[odd[i]][odd[j]];if val<dp[mask]{dp[mask]=val;pick[mask]=j}}}}
  mut multi:=[][]int{};for _ in 0..8{multi<<[]int{len:8,init:0}};for i in 0..n{for j in 0..n{if tree[i][j]{multi[i][j]=1}}};mut mask:=full
  for mask!=0{mut i:=0;for (mask&(1<<i))==0{i++};j:=pick[mask];u,v:=odd[i],odd[j];multi[u][v]++;multi[v][u]++;mask^=(1<<i)|(1<<j)}
  mut st:=[]int{cap:32};st<<0;mut rev:=[]int{};for st.len>0{v:=st[st.len-1];mut w:=-1;for x in 0..n{if multi[v][x]>0{w=x;break}};if w<0{rev<<st.pop()}else{multi[v][w]--;multi[w][v]--;st<<w}}
  mut seen:=[]bool{len:8,init:false};mut order:=[]int{};for i:=rev.len-1;i>=0;i--{v:=rev[i];if !seen[v]{seen[v]=true;order<<v}}
  mut cost:=i64(0);for i in 0..n-1{cost+=d[order[i]][order[i+1]]};cost+=d[order[n-1]][0];vals:=[]i64{len:n+2,init:0};vals[0]=cost;for i in 0..n{vals[i+1]=i64(order[i])}
  for i,x in vals{bits:=u64(x);for b in 0..8{output[8*i+b]=u8((bits>>(8*b))&255)}};return i64(bytes)
 }
}
