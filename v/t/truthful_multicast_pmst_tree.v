module main

const max_n = 8
const max_m = 28
const max_input = 95
const max_output = 176

fn find_root(mut parent [8]int, mut x int) int {
	for parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x] }
	return x
}

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for b in 0 .. 8 { output[offset+b] = u8((bits >> (b*8)) & 255) } }
}

@[export: 'truthful_multicast_pmst_tree']
pub fn truthful_multicast_pmst_tree(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length < 4 || length > max_input { return -1 }
		if values[0] < 2 || values[0] > max_n || values[1] < values[0]-1 || values[1] > max_m || values[2] < 0 || values[2] >= values[0] || values[3] < 1 || values[3] >= values[0] { return -1 }
		n,m,source,r := int(values[0]),int(values[1]),int(values[2]),int(values[3])
		if length != usize(4+3*m+r) { return -1 }
		mut eu := [28]int{}; mut ev := [28]int{}; mut ew := [28]int{}; mut order := [28]int{}
		mut pu,pv := i64(-1),i64(-1)
		for i in 0 .. m {
			u,v,w := values[4+3*i],values[5+3*i],values[6+3*i]
			if u<0||v<=u||v>=i64(n)||w<1||w>100||(i>0&&(u<pu||(u==pu&&v<=pv))){return -1}
			eu[i],ev[i],ew[i],order[i]=int(u),int(v),int(w),i;pu,pv=u,v
		}
		mut receivers := [8]int{};mut last := i64(-1)
		for i in 0 .. r { x:=values[4+3*m+i];if x<0||x>=i64(n)||x==i64(source)||(i>0&&x<=last){return -1};receivers[i]=int(x);last=x }
		for i := 1; i < m; i++ { key:=order[i];mut j:=i;for j>0 { q:=order[j-1];if ew[q]<ew[key]||(ew[q]==ew[key]&&(eu[q]<eu[key]||(eu[q]==eu[key]&&ev[q]<ev[key]))){break};order[j]=q;j-- };order[j]=key }
		mut dsu := [8]int{};for i in 0 .. n { dsu[i]=i }
		mut tu := [8]int{};mut tv := [8]int{};mut tw := [8]int{};mut te:=0
		for z in 0 .. m { if te>=n-1{break};e:=order[z];mut x:=find_root(mut dsu,eu[e]);mut y:=find_root(mut dsu,ev[e]);if x!=y{dsu[x]=y;tu[te]=eu[e];tv[te]=ev[e];tw[te]=ew[e];te++} }
		if te!=n-1{return -1}
		mut edge_at := [8][8]int{};for i in 0 .. n { for j in 0 .. n { edge_at[i][j] = -1 } };for e in 0 .. te { edge_at[tu[e]][tv[e]]=e;edge_at[tv[e]][tu[e]]=e }
		mut parent := [8]int{};mut parent_edge := [8]int{};for i in 0 .. n {parent[i] = -1;parent_edge[i] = -1};parent[source]=source
		mut stack := [8]int{};mut top:=1;stack[0]=source
		for top>0 {top--;u:=stack[top];for v in 0 .. n {e:=edge_at[u][v];if e>=0&&parent[v]<0{parent[v]=u;parent_edge[v]=e;stack[top]=v;top++}}}
		mut keep := [8]bool{};for i in 0 .. r {mut v:=receivers[i];for v!=source{if parent[v]<0{return -1};keep[parent_edge[v]]=true;v=parent[v]}}
		mut selected := [8]int{};mut count:=0;for e in 0 .. te {if keep[e]{selected[count]=e;count++}}
		for i:=1;i<count;i++{key:=selected[i];mut j:=i;for j>0&&(tu[selected[j-1]]>tu[key]||(tu[selected[j-1]]==tu[key]&&tv[selected[j-1]]>tv[key])){selected[j]=selected[j-1];j--};selected[j]=key}
		bytes:=8*(1+3*count);if output==nil||capacity<usize(bytes){return -2};mut staged:=[176]u8{};put_i64(mut staged[0],0,i64(count));for i in 0..count{e:=selected[i];put_i64(mut staged[0],8*(1+3*i),i64(tu[e]));put_i64(mut staged[0],8*(2+3*i),i64(tv[e]));put_i64(mut staged[0],8*(3+3*i),i64(tw[e]))};for i in 0..bytes{output[i]=staged[i]};return i64(bytes)
	}
}
