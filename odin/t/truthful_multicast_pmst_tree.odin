package truthful_multicast_pmst_tree

import "core:c"

MAX_N :: 8
MAX_M :: 28
MAX_INPUT :: 95
MAX_OUTPUT :: 176

find_root :: proc(parent: ^[MAX_N]int, x_input: int) -> int {
	x := x_input
	for parent^[x] != x { parent^[x] = parent^[parent^[x]]; x = parent^[x] }
	return x
}

put_i64 :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { output[offset+b] = u8((bits >> (b*8)) & 255) }
}

@(export)
truthful_multicast_pmst_tree :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || int(length) < 4 || int(length) > MAX_INPUT do return -1
	if values[0] < 2 || values[0] > MAX_N || values[1] < values[0]-1 || values[1] > MAX_M ||
		values[2] < 0 || values[2] >= values[0] || values[3] < 1 || values[3] >= values[0] do return -1
	n,m,source,r := int(values[0]),int(values[1]),int(values[2]),int(values[3])
	if int(length) != 4+3*m+r do return -1
	eu: [MAX_M]int; ev: [MAX_M]int; ew: [MAX_M]int; order: [MAX_M]int
	pu,pv := -1,-1
	for i := 0; i < m; i += 1 {
		u,v,w := values[4+3*i],values[5+3*i],values[6+3*i]
		if u < 0 || v <= u || v >= i64(n) || w < 1 || w > 100 || (i>0 && (u<i64(pu) || (u==i64(pu) && v<=i64(pv)))) do return -1
		eu[i],ev[i],ew[i],order[i]=int(u),int(v),int(w),i;pu,pv=int(u),int(v)
	}
	receivers: [MAX_N]int;last := -1
	for i := 0; i < r; i += 1 { x:=values[4+3*m+i];if x<0||x>=i64(n)||x==i64(source)||(i>0&&x<=i64(last))do return -1;receivers[i]=int(x);last=int(x) }
	for i := 1; i < m; i += 1 {key:=order[i];j:=i;for j>0 {q:=order[j-1];if ew[q]<ew[key]||(ew[q]==ew[key]&&(eu[q]<eu[key]||(eu[q]==eu[key]&&ev[q]<ev[key]))){break};order[j]=q;j-=1};order[j]=key}
	dsu: [MAX_N]int;for i:=0;i<n;i+=1{dsu[i]=i}
	tu: [MAX_N]int;tv: [MAX_N]int;tw: [MAX_N]int;te:=0
	for z:=0;z<m&&te<n-1;z+=1{e:=order[z];x:=find_root(&dsu,eu[e]);y:=find_root(&dsu,ev[e]);if x!=y{dsu[x]=y;tu[te]=eu[e];tv[te]=ev[e];tw[te]=ew[e];te+=1}}
	if te!=n-1 do return -1
	edge_at: [MAX_N][MAX_N]int;for i:=0;i<n;i+=1{for j:=0;j<n;j+=1{edge_at[i][j]=-1}};for e:=0;e<te;e+=1{edge_at[tu[e]][tv[e]]=e;edge_at[tv[e]][tu[e]]=e}
	parent: [MAX_N]int;parent_edge: [MAX_N]int;for i:=0;i<n;i+=1{parent[i]=-1;parent_edge[i]=-1};parent[source]=source
	stack: [MAX_N]int;top:=1;stack[0]=source
	for top>0{top-=1;u:=stack[top];for v:=0;v<n;v+=1{e:=edge_at[u][v];if e>=0&&parent[v]<0{parent[v]=u;parent_edge[v]=e;stack[top]=v;top+=1}}}
	keep: [MAX_N]bool;for i:=0;i<r;i+=1{v:=receivers[i];for v!=source{if parent[v]<0 do return -1;keep[parent_edge[v]]=true;v=parent[v]}}
	selected: [MAX_N]int;count:=0;for e:=0;e<te;e+=1{if keep[e]{selected[count]=e;count+=1}}
	for i:=1;i<count;i+=1{key:=selected[i];j:=i;for j>0&&(tu[selected[j-1]]>tu[key]||(tu[selected[j-1]]==tu[key]&&tv[selected[j-1]]>tv[key])){selected[j]=selected[j-1];j-=1};selected[j]=key}
	bytes:=8*(1+3*count);if output==nil||int(capacity)<bytes do return -2;staged: [MAX_OUTPUT]u8;put_i64(&staged[0],0,i64(count));for i:=0;i<count;i+=1{e:=selected[i];put_i64(&staged[0],8*(1+3*i),i64(tu[e]));put_i64(&staged[0],8*(2+3*i),i64(tv[e]));put_i64(&staged[0],8*(3+3*i),i64(tw[e]))};for i:=0;i<bytes;i+=1{output[i]=staged[i]};return i64(bytes)
}
