module st_planar_leftmost_augmenting_flow
const max_n=6
const max_m=10
const max_input=60
fn put_i64(mut output &u8,value i64){bits:=u64(value);for b in 0..8{unsafe{output[b]=u8((bits>>(8*b))&255)}}}
@[export:'st_planar_leftmost_augmenting_flow']
pub fn st_planar_leftmost_augmenting_flow(input &i64,length usize,mut output &u8,capacity usize)i64{
 if input==nil||length<4||length>max_input{return -1};n0:=unsafe{input[0]};m0:=unsafe{input[1]};s0:=unsafe{input[2]};t0:=unsafe{input[3]};if n0<2||n0>max_n||m0<1||m0>max_m||s0<0||s0>=n0||t0<0||t0>=n0||s0==t0{return -1}
 n:=int(n0);m:=int(m0);s:=int(s0);t:=int(t0);if length<usize(4+3*m){return -1};mut eu:=[max_m]int{};mut ev:=[max_m]int{};mut caps:=[max_m]int{};mut pairs:=[max_n*max_n]bool{};mut at:=4
 for e in 0..m{u:=unsafe{input[at]};v:=unsafe{input[at+1]};c:=unsafe{input[at+2]};at+=3;if u<0||u>=n0||v<0||v>=n0||u==v||c<0||c>5{return -1};a:=int(u)*max_n+int(v);b:=int(v)*max_n+int(u);if pairs[a]||pairs[b]{return -1};pairs[a]=true;pairs[b]=true;eu[e]=int(u);ev[e]=int(v);caps[e]=int(c)}
 mut degree:=[max_n]int{};mut rot:=[max_n][max_n]int{};mut occ:=[max_m*2]int{};mut used:=[max_n*max_m]bool{}
 for x in 0..n{if at>=int(length){return -1};d:=unsafe{input[at]};at++;if d<0||d>=n||at+int(d)>int(length){return -1};degree[x]=int(d);for j in 0..degree[x]{e0:=unsafe{input[at]};at++;if e0<0||e0>=m0{return -1};e:=int(e0);idx:=x*max_m+e;if used[idx]{return -1};used[idx]=true;rot[x][j]=e;if eu[e]==x{occ[e*2]++}else if ev[e]==x{occ[e*2+1]++}else{return -1}}}
 if at!=int(length){return -1};for e in 0..m{if occ[e*2]!=1||occ[e*2+1]!=1{return -1}}
 mut seen:=[max_n]bool{};mut q:=[max_n]int{};mut head:=0;mut tail:=0;seen[s]=true;q[tail]=s;tail++;for head<tail{x:=q[head];head++;for e in 0..m{mut y:=-1;if eu[e]==x{y=ev[e]}else if ev[e]==x{y=eu[e]};if y>=0&&!seen[y]{seen[y]=true;q[tail]=y;tail++}}};for x in 0..n{if !seen[x]{return -1}}
 mut flow:=[max_m]int{};mut total:=0
 for{mut vis:=[max_n]bool{};mut par:=[max_n]int{};mut pe:=[max_n]int{};mut pd:=[max_n]int{};mut next:=[max_n]int{};for x in 0..n{par[x]=-1;pe[x]=-1};mut stack:=[max_n]int{};mut top:=0;vis[s]=true;stack[top]=s;top++
  for top>0&&!vis[t]{x:=stack[top-1];if next[x]>=degree[x]{top--;continue};e:=rot[x][next[x]];next[x]++;mut y:=eu[e];mut rem:=flow[e];mut dir:=-1;if eu[e]==x{y=ev[e];rem=caps[e]-flow[e];dir=1};if rem>0&&!vis[y]{vis[y]=true;par[y]=x;pe[y]=e;pd[y]=dir;stack[top]=y;top++}}
  if !vis[t]{break};mut delta:=1000000;mut y:=t;for y!=s{x:=par[y];e:=pe[y];mut r:=flow[e];if eu[e]==x{r=caps[e]-flow[e]};if r<delta{delta=r};y=x};y=t;for y!=s{e:=pe[y];flow[e]+=pd[y]*delta;y=par[y]};total+=delta
 }
 if output==nil||capacity<8{return -2};put_i64(mut output,i64(total));return 8
}
