package steiner_tree_gain_greedy

import "core:c"

N :: 4
MAX_INPUT :: 37
Edge :: struct {u, v: int, w: i64}

put_i64 :: proc(out: [^]u8, word: int, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[word*8+b] = u8((bits >> u64(8*b)) & 255) }
}
find_root :: proc(p: ^[4]int, x0: int) -> int {
	x := x0
	for p^[x] != x { p^[x] = p^[p^[x]]; x = p^[x] }
	return x
}
join :: proc(p: ^[4]int, a, b: int) -> bool {
	ra := find_root(p,a); rb := find_root(p,b)
	if ra == rb do return false
	p^[rb] = ra
	return true
}
group_count :: proc(n: int, mask: i64, h: [4][4]bool) -> int {
	p: [4]int
	for i := 0; i < 4; i += 1 { p[i] = i }
	for i := 0; i < n; i += 1 { for j := i+1; j < n; j += 1 { if h[i][j] do join(&p,i,j) } }
	seen: [4]bool
	count := 0
	for i := 0; i < n; i += 1 { if (mask & (i64(1)<<i)) != 0 {
		r := find_root(&p,i)
		if !seen[r] { seen[r] = true; count += 1 }
	} }
	return count
}
less_edge :: proc(a,b: Edge) -> bool {
	return a.w < b.w || (a.w == b.w && (a.u < b.u || (a.u == b.u && a.v < b.v)))
}
metric_mst :: proc(n: int, mask: i64, w: [4][4]i64) -> i64 {
	verts: [4]int; vn := 0
	for i := 0; i < n; i += 1 { if (mask & (i64(1)<<i)) != 0 { verts[vn]=i; vn+=1 } }
	if vn <= 1 do return 0
	used: [4]bool; best: [4]i64
	used[verts[0]] = true
	for j := 1; j < vn; j += 1 { best[verts[j]] = w[verts[0]][verts[j]] }
	total: i64 = 0
	for step := 1; step < vn; step += 1 {
		pick := -1
		for z := 0; z < vn; z += 1 { v := verts[z]; if !used[v] && (pick < 0 || best[v] < best[pick] || (best[v] == best[pick] && v < pick)) do pick = v }
		total += best[pick]; used[pick] = true
		for z := 0; z < vn; z += 1 { v := verts[z]; if !used[v] && w[pick][v] < best[v] do best[v] = w[pick][v] }
	}
	return total
}
mst_h :: proc(n: int, w: [4][4]i64, h: [4][4]bool, tree: ^[3]Edge, tree_n: ^int) -> i64 {
	es: [6]Edge; en := 0
	for i := 0; i < n; i += 1 { for j := i+1; j < n; j += 1 { if h[i][j] { es[en]=Edge{i,j,w[i][j]}; en+=1 } } }
	for i := 1; i < en; i += 1 { x:=es[i]; j:=i; for j>0 && less_edge(x,es[j-1]) {es[j]=es[j-1];j-=1}; es[j]=x }
	p: [4]int; for i:=0;i<4;i+=1 {p[i]=i}
	cost:i64=0; used:=0
	for i:=0;i<en;i+=1 { e:=es[i]; if join(&p,e.u,e.v) {tree^[used]=e;used+=1;cost+=e.w} }
	tree_n^=used
	return cost
}
contracted_mst :: proc(n: int, mask:i64,w:[4][4]i64,h:[4][4]bool)->i64 {
	d:=w; p:[4]int; for i:=0;i<4;i+=1 {p[i]=i}
	for i:=0;i<n;i+=1 {for j:=i+1;j<n;j+=1 {if h[i][j] {d[i][j]=0;d[j][i]=0;join(&p,i,j)}}}
	for k:=0;k<n;k+=1 {for i:=0;i<n;i+=1 {for j:=0;j<n;j+=1 {if d[i][j]>d[i][k]+d[k][j] do d[i][j]=d[i][k]+d[k][j]}}}
	roots:[4]int; g:=0
	for v:=0;v<n;v+=1 {if (mask&(i64(1)<<v))!=0 {r:=find_root(&p,v); found:=false;for x:=0;x<g;x+=1 {if roots[x]==r do found=true};if !found {roots[g]=r;g+=1}}}
	if g<=1 do return 0
	q:[4][4]i64
	for a:=0;a<g;a+=1 {for b:=a+1;b<g;b+=1 {best:i64=1<<60;for u:=0;u<n;u+=1 {if find_root(&p,u)==roots[a] {for v:=0;v<n;v+=1 {if find_root(&p,v)==roots[b] && d[u][v]<best do best=d[u][v]}}};q[a][b]=best;q[b][a]=best}}
	used:[4]bool; best:[4]i64;used[0]=true;for j:=1;j<g;j+=1 {best[j]=q[0][j]};total:i64=0
	for step:=1;step<g;step+=1 {pick:=-1;for v:=0;v<g;v+=1 {if !used[v]&&(pick<0||best[v]<best[pick]||(best[v]==best[pick]&&v<pick)) do pick=v};total+=best[pick];used[pick]=true;for v:=0;v<g;v+=1 {if !used[v]&&q[pick][v]<best[v] do best[v]=q[pick][v]}}
	return total
}

steiner_tree_gain_greedy :: proc "c" (input: [^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
	if input==nil||length<4||length>MAX_INPUT do return -1
	n0:=input[0];mask:=input[1];count0:=input[2]
	if n0<2||n0>4||mask<=0||(mask>>n0)!=0||count0<1||count0>4 do return -1
	n:=int(n0);count:=int(count0);terms:=0
	for i:=0;i<n;i+=1 {if (mask&(i64(1)<<i))!=0 do terms+=1};if terms<2 do return -1
	w:[4][4]i64;at:=3
	for i:=0;i<n;i+=1 {for j:=i+1;j<n;j+=1 {if at>=int(length)||input[at]<0||input[at]>1000 do return -1;w[i][j]=input[at];w[j][i]=input[at];at+=1}}
	for i:=0;i<n;i+=1 {for j:=0;j<n;j+=1 {for k:=0;k<n;k+=1 {if w[i][j]>w[i][k]+w[k][j] do return -1}}}
	family:[4][3]Edge; sizes:[4]int; family_h:[4][4]bool
	for cidx:=0;cidx<count;cidx+=1 {
		if at>=int(length) do return -1
		ec0:=input[at];at+=1;if ec0<1||ec0>n0-1||at+2*int(ec0)>int(length) do return -1
		p:[4]int;degree:[4]int;for i:=0;i<4;i+=1 {p[i]=i};ec:=int(ec0)
		for e:=0;e<ec;e+=1 {u0:=input[at];v0:=input[at+1];at+=2;if u0<0||u0>=n0||v0<0||v0>=n0||u0==v0 do return -1;u:=int(u0);v:=int(v0);if !join(&p,u,v) do return -1
			if u>v {tmp:=u;u=v;v=tmp};for x:=0;x<e;x+=1 {if family[cidx][x].u==u&&family[cidx][x].v==v do return -1};family[cidx][e]=Edge{u,v,0};family_h[u][v]=true;family_h[v][u]=true;degree[u]+=1;degree[v]+=1}
		verts:=0;leaves:=0;first:=-1
		for v:=0;v<n;v+=1 {if degree[v]>0 {if first<0 {first=find_root(&p,v)} else if find_root(&p,v)!=first do return -1;verts+=1;if degree[v]==1 {if (mask&(i64(1)<<v))==0 do return -1;leaves+=1} else if (mask&(i64(1)<<v))!=0 do return -1}}
		if verts!=ec+1||leaves<2||leaves>3 do return -1;sizes[cidx]=ec
	}
	if at!=int(length)||group_count(n,mask,family_h)!=1 do return -1
	baseline:=metric_mst(n,mask,w);h:[4][4]bool;selected:[4]bool
	for group_count(n,mask,h)>1 {before:=group_count(n,mask,h);best:=-1;best_gain:i64=-(1<<60)
		for cidx:=0;cidx<count;cidx+=1 {if selected[cidx] do continue;trial:=h;for e:=0;e<sizes[cidx];e+=1 {u:=family[cidx][e].u;v:=family[cidx][e].v;trial[u][v]=true;trial[v][u]=true};if group_count(n,mask,trial)>=before do continue
			unused:[3]Edge;unused_n:=0;gain:=baseline-contracted_mst(n,mask,w,trial)-mst_h(n,w,trial,&unused,&unused_n);if best<0||gain>best_gain {best=cidx;best_gain=gain}}
		if best<0 do return -1;selected[best]=true;for e:=0;e<sizes[best];e+=1 {u:=family[best][e].u;v:=family[best][e].v;h[u][v]=true;h[v][u]=true}}
	tree:[3]Edge;tree_n:=0;cost:=mst_h(n,w,h,&tree,&tree_n);bytes:=8*(3+2*tree_n);if output==nil||capacity<c.size_t(bytes) do return -2
	put_i64(output,0,1);put_i64(output,1,cost);put_i64(output,2,i64(tree_n));for i:=0;i<tree_n;i+=1 {put_i64(output,3+2*i,i64(tree[i].u));put_i64(output,4+2*i,i64(tree[i].v))};return i64(bytes)
}
