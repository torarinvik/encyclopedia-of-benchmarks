module steiner_tree_gain_greedy

struct Edge { u int; v int; w i64 }
const nmax = 4

fn put_i64(mut out &u8, word int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { out[word * 8 + b] = u8((bits >> u64(8 * b)) & 255) } }
}
fn root(mut p [4]int, x0 int) int {
	mut x := x0
	for p[x] != x { p[x] = p[p[x]]; x = p[x] }
	return x
}
fn join(mut p [4]int, a int, b int) bool {
	ra := root(mut p,a); rb := root(mut p,b)
	if ra == rb { return false }
	p[rb] = ra
	return true
}
fn group_count(n int, mask i64, h [4][4]bool) int {
	mut p := [4]int{}
	for i in 0 .. 4 { p[i] = i }
	for i in 0 .. n { for j in i+1 .. n { if h[i][j] { join(mut p,i,j) } } }
	mut seen := [4]bool{}
	mut count := 0
	for i in 0 .. n { if (mask & (i64(1) << i)) != 0 { r := root(mut p,i); if !seen[r] {seen[r]=true;count++} } }
	return count
}
fn less_edge(a Edge,b Edge) bool { return a.w<b.w || (a.w==b.w && (a.u<b.u || (a.u==b.u && a.v<b.v))) }
fn metric_mst(n int, mask i64, w [4][4]i64) i64 {
	mut verts := []int{}
	for i in 0 .. n { if (mask & (i64(1)<<i))!=0 {verts << i} }
	if verts.len<=1 {return 0}
	mut used := [4]bool{}
	mut best := [4]i64{}
	for i in 0 .. 4 {best[i]=i64(0x7fffffffffffffff)}
	used[verts[0]]=true
	for j in 1 .. verts.len {best[verts[j]]=w[verts[0]][verts[j]]}
	mut total := i64(0)
	for _ in 1 .. verts.len {mut pick:=-1;for v in verts {if !used[v]&&(pick<0||best[v]<best[pick]||(best[v]==best[pick]&&v<pick)){pick=v}};total+=best[pick];used[pick]=true;for v in verts{if !used[v]&&w[pick][v]<best[v]{best[v]=w[pick][v]}}}
	return total
}
fn mst_h(n int,w [4][4]i64,h [4][4]bool,mut tree [3]Edge,mut tree_n int) i64 {
	mut es := []Edge{}
	for i in 0 .. n {for j in i+1 .. n {if h[i][j]{es<<Edge{i,j,w[i][j]}}}}
	for i in 1 .. es.len {x:=es[i];mut j:=i;for j>0&&less_edge(x,es[j-1]){es[j]=es[j-1];j--};es[j]=x}
	mut p:=[4]int{};for i in 0..4{p[i]=i};mut cost:=i64(0);tree_n=0
	for e in es{if join(mut p,e.u,e.v){tree[tree_n]=e;tree_n++;cost+=e.w}}
	return cost
}
fn contracted_mst(n int,mask i64,w [4][4]i64,h [4][4]bool)i64{
	mut d:=w;mut p:=[4]int{};for i in 0..4{p[i]=i}
	for i in 0..n{for j in i+1..n{if h[i][j]{d[i][j]=0;d[j][i]=0;join(mut p,i,j)}}}
	for k in 0..n{for i in 0..n{for j in 0..n{if d[i][j]>d[i][k]+d[k][j]{d[i][j]=d[i][k]+d[k][j]}}}}
	mut roots:=[]int{};for v in 0..n{if(mask&(i64(1)<<v))!=0{r:=root(mut p,v);if r !in roots{roots<<r}}};if roots.len<=1{return 0}
	mut q:=[4][4]i64{};for a in 0..roots.len{for b in a+1..roots.len{mut best:=i64(0x7fffffffffffffff);for u in 0..n{if root(mut p,u)==roots[a]{for v in 0..n{if root(mut p,v)==roots[b]&&d[u][v]<best{best=d[u][v]}}}};q[a][b]=best;q[b][a]=best}}
	mut used:=[4]bool{};mut best:=[4]i64{};for i in 0..4{best[i]=i64(0x7fffffffffffffff)};used[0]=true;for j in 1..roots.len{best[j]=q[0][j]};mut total:=i64(0)
	for _ in 1..roots.len{mut pick:=-1;for v in 0..roots.len{if !used[v]&&(pick<0||best[v]<best[pick]||(best[v]==best[pick]&&v<pick)){pick=v}};total+=best[pick];used[pick]=true;for v in 0..roots.len{if !used[v]&&q[pick][v]<best[v]{best[v]=q[pick][v]}}}
	return total
}

@[export: 'steiner_tree_gain_greedy']
pub fn steiner_tree_gain_greedy(input &i64,length usize,mut output &u8,capacity usize)i64{
	if input==nil||length<4||length>37{return -1}
	unsafe{
		n0:=input[0];mask:=input[1];count0:=input[2];if n0<2||n0>4||mask<=0||(mask>>n0)!=0||count0<1||count0>4{return -1};n:=int(n0);count:=int(count0)
		mut terms:=0;for i in 0..n{if(mask&(i64(1)<<i))!=0{terms++}};if terms<2{return -1}
		mut w:=[4][4]i64{};mut at:=3
		for i in 0..n{for j in i+1..n{if at>=int(length)||input[at]<0||input[at]>1000{return -1};w[i][j]=input[at];w[j][i]=input[at];at++}}
		for i in 0..n{for j in 0..n{for k in 0..n{if w[i][j]>w[i][k]+w[k][j]{return -1}}}}
		mut fam:=[4][3]Edge{};mut sizes:=[4]int{};mut fh:=[4][4]bool{}
		for c in 0..count{if at>=int(length){return -1};ec0:=input[at];at++;if ec0<1||ec0>n0-1||at+2*int(ec0)>int(length){return -1};ec:=int(ec0);mut p:=[4]int{};mut degree:=[4]int{};for i in 0..4{p[i]=i}
			for e in 0..ec{u0:=input[at];v0:=input[at+1];at+=2;if u0<0||u0>=n0||v0<0||v0>=n0||u0==v0{return -1};mut u:=int(u0);mut v:=int(v0);if !join(mut p,u,v){return -1};if u>v{tmp:=u;u=v;v=tmp};for x in 0..e{if fam[c][x].u==u&&fam[c][x].v==v{return -1}};fam[c][e]=Edge{u,v,0};fh[u][v]=true;fh[v][u]=true;degree[u]++;degree[v]++}
			mut seen:=0;mut leaves:=0;mut first:=-1;for v in 0..n{if degree[v]>0{if first<0{first=root(mut p,v)}else if root(mut p,v)!=first{return -1};seen++;if degree[v]==1{if(mask&(i64(1)<<v))==0{return -1};leaves++}else if(mask&(i64(1)<<v))!=0{return -1}}};if seen!=ec+1||leaves<2||leaves>3{return -1};sizes[c]=ec
		}
		if at!=int(length)||group_count(n,mask,fh)!=1{return -1};baseline:=metric_mst(n,mask,w);mut h:=[4][4]bool{};mut selected:=[4]bool{}
		for group_count(n,mask,h)>1{before:=group_count(n,mask,h);mut best:=-1;mut best_gain:=i64(-0x7fffffffffffffff)
			for c in 0..count{if selected[c]{continue};mut trial:=h;for e in 0..sizes[c]{u:=fam[c][e].u;v:=fam[c][e].v;trial[u][v]=true;trial[v][u]=true};if group_count(n,mask,trial)>=before{continue};mut scratch:=[3]Edge{};mut scratch_n:=0;gain:=baseline-contracted_mst(n,mask,w,trial)-mst_h(n,w,trial,mut scratch,mut scratch_n);if best<0||gain>best_gain{best=c;best_gain=gain}}
			if best<0{return -1};selected[best]=true;for e in 0..sizes[best]{u:=fam[best][e].u;v:=fam[best][e].v;h[u][v]=true;h[v][u]=true}}
		mut tree:=[3]Edge{};mut tree_n:=0;cost:=mst_h(n,w,h,mut tree,mut tree_n);bytes:=8*(3+2*tree_n);if output==nil||capacity<usize(bytes){return -2};put_i64(mut output,0,1);put_i64(mut output,1,cost);put_i64(mut output,2,i64(tree_n));for i in 0..tree_n{put_i64(mut output,3+2*i,i64(tree[i].u));put_i64(mut output,4+2*i,i64(tree[i].v))};return i64(bytes)
	}
}
