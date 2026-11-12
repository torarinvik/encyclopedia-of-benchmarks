package dynamic_point_set_rectangle_affine_rectangle_sum

import "core:c"

Max_N :: 32
Max_Q :: 32
Max_Points :: Max_N + Max_Q
Max_Tree :: 4 * Max_Points + 8
Max_Input :: 2 + 3 * Max_N + 7 * Max_Q + 1
Mod :: i64(998244353)
Max_Coord :: i64(1000000000)

Op :: struct { kind, a, b, c, d, e, f: i64 }
Node :: struct { min_x, max_x, min_y, max_y, sum, lazy_a, lazy_b: i64, active: int }

less_point :: proc(a, b, axis: int, xs, ys: ^[Max_Points]i64) -> bool {
	av := xs[a]; bv := xs[b]; ao := ys[a]; bo := ys[b]
	if axis != 0 { av, bv = ys[a], ys[b]; ao, bo = xs[a], xs[b] }
	if av != bv { return av < bv }; if ao != bo { return ao < bo }; return a < b
}
sort_points :: proc(order: ^[Max_Points]int, low, high, axis: int, xs, ys: ^[Max_Points]i64) {
	for i := low + 1; i < high; i += 1 {
		point := order[i]; j := i
		for j > low && less_point(point, order[j-1], axis, xs, ys) { order[j] = order[j-1]; j -= 1 }
		order[j] = point
	}
}
build :: proc(tree: ^[Max_Tree]Node, order: ^[Max_Points]int, rank: ^[Max_Points]int,
	xs, ys, weights: ^[Max_Points]i64, low, high, index, depth, initial_n: int) {
	tree[index].lazy_a = 1
	if high-low == 1 {
		p := order[low]; tree[index].min_x = xs[p]; tree[index].max_x = xs[p]; tree[index].min_y = ys[p]; tree[index].max_y = ys[p]
		if p < initial_n { tree[index].active = 1; tree[index].sum = weights[p] }
		rank[p] = low; return
	}
	sort_points(order, low, high, depth & 1, xs, ys); mid := low + (high-low)/2
	build(tree, order, rank, xs, ys, weights, low, mid, index*2, depth+1, initial_n)
	build(tree, order, rank, xs, ys, weights, mid, high, index*2+1, depth+1, initial_n)
	l, r := tree[index*2], tree[index*2+1]
	tree[index].min_x = min(l.min_x,r.min_x); tree[index].max_x = max(l.max_x,r.max_x)
	tree[index].min_y = min(l.min_y,r.min_y); tree[index].max_y = max(l.max_y,r.max_y)
	tree[index].active = l.active+r.active; tree[index].sum = (l.sum+r.sum)%Mod
}
apply :: proc(tree: ^[Max_Tree]Node, i: int, a,b: i64) {
	if tree[i].active == 0 { return }
	tree[i].sum = (a*tree[i].sum+b*i64(tree[i].active))%Mod
	tree[i].lazy_a = a*tree[i].lazy_a%Mod; tree[i].lazy_b = (a*tree[i].lazy_b+b)%Mod
}
push :: proc(tree: ^[Max_Tree]Node, i,low,high: int) {
	if high-low==1 || (tree[i].lazy_a==1 && tree[i].lazy_b==0) { return }
	apply(tree,i*2,tree[i].lazy_a,tree[i].lazy_b); apply(tree,i*2+1,tree[i].lazy_a,tree[i].lazy_b)
	tree[i].lazy_a=1; tree[i].lazy_b=0
}
disjoint :: proc(n: Node,l,d,r,u: i64)->bool { return n.max_x<l || n.min_x>=r || n.max_y<d || n.min_y>=u }
covered :: proc(n: Node,l,d,r,u: i64)->bool { return l<=n.min_x && n.max_x<r && d<=n.min_y && n.max_y<u }
pull :: proc(tree: ^[Max_Tree]Node,i:int) { tree[i].sum=(tree[i*2].sum+tree[i*2+1].sum)%Mod; tree[i].active=tree[i*2].active+tree[i*2+1].active }
rect_sum :: proc(tree: ^[Max_Tree]Node,i,low,high:int,l,d,r,u:i64)->i64 {
	n:=tree[i]; if n.active==0 || disjoint(n,l,d,r,u) { return 0 }; if covered(n,l,d,r,u) { return n.sum }
	push(tree,i,low,high); mid:=low+(high-low)/2
	return (rect_sum(tree,i*2,low,mid,l,d,r,u)+rect_sum(tree,i*2+1,mid,high,l,d,r,u))%Mod
}
rect_affine :: proc(tree: ^[Max_Tree]Node,i,low,high:int,l,d,r,u,a,b:i64) {
	n:=tree[i]; if n.active==0 || disjoint(n,l,d,r,u) { return }; if covered(n,l,d,r,u) { apply(tree,i,a,b); return }
	push(tree,i,low,high); mid:=low+(high-low)/2
	rect_affine(tree,i*2,low,mid,l,d,r,u,a,b); rect_affine(tree,i*2+1,mid,high,l,d,r,u,a,b); pull(tree,i)
}
set_point :: proc(tree: ^[Max_Tree]Node,i,low,high,target:int,weight:i64) {
	if high-low==1 { tree[i].sum=weight; tree[i].active=1; tree[i].lazy_a=1; tree[i].lazy_b=0; return }
	push(tree,i,low,high); mid:=low+(high-low)/2
	if target<mid { set_point(tree,i*2,low,mid,target,weight) } else { set_point(tree,i*2+1,mid,high,target,weight) }; pull(tree,i)
}
put64 :: proc(output: [^]u8, pos: int, value: i64) { bits:=u64(value); for b:=0;b<8;b+=1 { output[pos+b]=u8((bits>>(8*b))&255) } }

@(export)
dynamic_point_set_rectangle_affine_rectangle_sum :: proc "c" (input: [^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
	if input==nil || length<2 || length>c.size_t(Max_Input) do return -1
	nv,qv:=input[0],input[1]; if nv<1 || nv>Max_N || qv<1 || qv>Max_Q do return -1
	n,q:=int(nv),int(qv); if 2+3*n>int(length) do return -1
	xs:[Max_Points]i64; ys:[Max_Points]i64; weights:[Max_Points]i64; ops:[Max_Q]Op
	points,active,query_count:=n,n,0
	for i:=0;i<n;i+=1 { xs[i]=input[2+3*i]; ys[i]=input[3+3*i]; weights[i]=input[4+3*i]
		if xs[i]<0 || xs[i]>Max_Coord || ys[i]<0 || ys[i]>Max_Coord || weights[i]<0 || weights[i]>=Mod do return -1 }
	cursor:=2+3*n
	for oi:=0;oi<q;oi+=1 {
		if cursor>=int(length) do return -1; kind:=input[cursor]; cursor+=1
		if kind==0 {
			if cursor+3>int(length) || points>=Max_Points do return -1
			x,y,w:=input[cursor],input[cursor+1],input[cursor+2]; cursor+=3
			if x<0 || x>Max_Coord || y<0 || y>Max_Coord || w<0 || w>=Mod do return -1
			xs[points]=x; ys[points]=y; ops[oi]=Op{kind,i64(points),w,0,0,0,0}; points+=1; active+=1
		} else if kind==1 {
			if cursor+2>int(length) do return -1; id,w:=input[cursor],input[cursor+1]; cursor+=2
			if id<0 || id>=i64(active) || w<0 || w>=Mod do return -1; ops[oi]=Op{kind,id,w,0,0,0,0}
		} else if kind==2 || kind==3 {
			fields:=4; if kind==3 { fields=6 }; if cursor+fields>int(length) do return -1
			l,d,r,u:=input[cursor],input[cursor+1],input[cursor+2],input[cursor+3]
			if l<0 || l>=r || r>Max_Coord || d<0 || d>=u || u>Max_Coord do return -1
			if kind==2 { cursor+=4; ops[oi]=Op{kind,l,d,r,u,0,0}; query_count+=1 }
			else { a,b:=input[cursor+4],input[cursor+5]; cursor+=6; if a<0 || a>=Mod || b<0 || b>=Mod do return -1; ops[oi]=Op{kind,l,d,r,u,a,b} }
		} else { return -1 }
	}
	if cursor!=int(length) do return -1; bytes:=8*query_count
	if bytes>0 && (output==nil || capacity<c.size_t(bytes)) do return -2
	tree:[Max_Tree]Node; order:[Max_Points]int; rank:[Max_Points]int
	for i:=0;i<points;i+=1 { order[i]=i }; build(&tree,&order,&rank,&xs,&ys,&weights,0,points,1,0,n)
	answers:[Max_Q]i64; answer_count:=0
	for oi:=0;oi<q;oi+=1 { op:=ops[oi]
		if op.kind==0 || op.kind==1 { set_point(&tree,1,0,points,rank[int(op.a)],op.b) }
		else if op.kind==2 { answers[answer_count]=rect_sum(&tree,1,0,points,op.a,op.b,op.c,op.d); answer_count+=1 }
		else { rect_affine(&tree,1,0,points,op.a,op.b,op.c,op.d,op.e,op.f) }
	}
	for i:=0;i<answer_count;i+=1 { put64(output,8*i,answers[i]) }; return i64(bytes)
}
