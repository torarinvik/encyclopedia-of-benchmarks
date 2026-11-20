package fakcharoenphol_rao_planar_sssp

import "core:c"

MAX_N :: 12
MAX_M :: 60
MAX_P :: 119
MAX_B :: 12
MAX_BLOCKS :: 44
MAX_INPUT :: 2088
INF :: i64(1152921504606846976)

Arc :: struct { tail, head: int, weight: i64 }
Piece :: struct {
	left, right, boundary_count: int,
	arc_mask: u64,
	vertex_mask: u16,
	boundary: [MAX_B]int,
}
Block :: struct {
	child, row_count, column_count: int,
	rows, columns: [MAX_B]int,
	weights: [MAX_B][MAX_B]i64,
	best_value: [MAX_B]i64,
	best_row: [MAX_B]int,
}
Context :: struct {
	n, m, source, piece_count: int,
	pieces: [MAX_P]Piece,
	arcs: [MAX_M]Arc,
	ddg: [MAX_P][MAX_N][MAX_N]i64,
	potential: [MAX_P][MAX_N]i64,
}

pop_count16 :: proc "contextless" (value: u16) -> int {
	result := 0
	v := value
	for v != 0 { result += int(v & 1); v >>= 1 }
	return result
}

pop_count64 :: proc "contextless" (value: u64) -> int {
	result := 0
	v := value
	for v != 0 { result += int(v & 1); v >>= 1 }
	return result
}

vertex_mask :: proc (ctx: ^Context, mask: u64) -> u16 {
	result: u16 = 0
	for edge := 0; edge < ctx.m; edge += 1 {
		if mask & (u64(1) << u64(edge)) != 0 {
			result |= u16(1) << u16(ctx.arcs[edge].tail)
			result |= u16(1) << u16(ctx.arcs[edge].head)
		}
	}
	return result
}

piece_connected :: proc (ctx: ^Context, mask: u64, vertices: u16) -> bool {
	if vertices == 0 do return false
	start := 0
	for vertices & (u16(1) << u16(start)) == 0 { start += 1 }
	reached := u16(1) << u16(start)
	changed := true
	for changed {
		changed = false
		for edge := 0; edge < ctx.m; edge += 1 {
			if mask & (u64(1) << u64(edge)) == 0 do continue
			u, v := ctx.arcs[edge].tail, ctx.arcs[edge].head
			ub, vb := u16(1) << u16(u), u16(1) << u16(v)
			if reached & ub != 0 && reached & vb == 0 { reached |= vb; changed = true }
			if reached & vb != 0 && reached & ub == 0 { reached |= ub; changed = true }
		}
	}
	return reached == vertices
}

parse :: proc (ctx: ^Context, input: [^]i64, length: c.size_t) -> bool {
	if input == nil || length < 4 || length > MAX_INPUT do return false
	n0, m0, source0, piece_count0 := input[0], input[1], input[2], input[3]
	if n0 < 2 || n0 > MAX_N || m0 < 1 || m0 > MAX_M || source0 < 0 || source0 >= n0 || piece_count0 < 1 || piece_count0 > MAX_P || piece_count0 % 2 == 0 do return false
	ctx.n, ctx.m, ctx.source, ctx.piece_count = int(n0), int(m0), int(source0), int(piece_count0)
	var seen_arc: [MAX_N][MAX_N]bool
	var seen_pair: [MAX_N][MAX_N]bool
	pair_count := 0
	offset := 4
	for edge := 0; edge < ctx.m; edge += 1 {
		if offset + 3 > int(length) do return false
		u0, v0, weight := input[offset], input[offset+1], input[offset+2]
		offset += 3
		if u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 || weight < -100 || weight > 100 do return false
		u, v := int(u0), int(v0)
		if seen_arc[u][v] do return false
		seen_arc[u][v] = true
		if !seen_pair[u][v] { seen_pair[u][v] = true; seen_pair[v][u] = true; pair_count += 1 }
		ctx.arcs[edge] = Arc{u, v, weight}
	}
	edge_limit := 3*ctx.n - 6
	if ctx.n == 2 { edge_limit = 1 }
	if pair_count > edge_limit || ctx.m > 2*edge_limit do return false
	var visited: [MAX_N]bool
	var queue: [MAX_N]int
	head, tail := 0, 1
	visited[0] = true; queue[0] = 0
	for head < tail {
		u := queue[head]; head += 1
		for edge := 0; edge < ctx.m; edge += 1 {
			v := -1
			if ctx.arcs[edge].tail == u { v = ctx.arcs[edge].head }
			else if ctx.arcs[edge].head == u { v = ctx.arcs[edge].tail }
			if v >= 0 && !visited[v] { visited[v] = true; queue[tail] = v; tail += 1 }
		}
	}
	for v := 0; v < ctx.n; v += 1 { if !visited[v] do return false }

	var parents: [MAX_P]int
	leaf_union: u64 = 0
	leaf_count := 0
	full := (u64(1) << u64(ctx.m)) - 1
	for index := 0; index < ctx.piece_count; index += 1 {
		if offset + 4 > int(length) do return false
		left0, right0, mask0, bc0 := input[offset], input[offset+1], input[offset+2], input[offset+3]
		offset += 4
		if bc0 < 1 || bc0 > n0 || bc0 > MAX_B || offset+int(bc0) > int(length) do return false
		piece := Piece{left = int(left0), right = int(right0), boundary_count = int(bc0)}
		listed: u16 = 0
		for j := 0; j < piece.boundary_count; j += 1 {
			v0 := input[offset]; offset += 1
			if v0 < 0 || v0 >= n0 do return false
			v := int(v0); bit := u16(1) << u16(v)
			if listed & bit != 0 do return false
			listed |= bit; piece.boundary[j] = v
		}
		if left0 == -1 && right0 == -1 {
			if mask0 <= 0 do return false
			piece.arc_mask = u64(mask0)
			if piece.arc_mask & ~full != 0 || pop_count64(piece.arc_mask) > 3 || leaf_union & piece.arc_mask != 0 do return false
			leaf_union |= piece.arc_mask; leaf_count += 1
			piece.vertex_mask = vertex_mask(ctx, piece.arc_mask)
			if !piece_connected(ctx, piece.arc_mask, piece.vertex_mask) do return false
		} else {
			if left0 < 0 || right0 < 0 || left0 >= int64(index) || right0 >= int64(index) || left0 == right0 || mask0 != -1 do return false
			left, right := int(left0), int(right0)
			if parents[left] != 0 || parents[right] != 0 do return false
			parents[left] = 1; parents[right] = 1
			lp, rp := ctx.pieces[left], ctx.pieces[right]
			if lp.arc_mask & rp.arc_mask != 0 do return false
			piece.arc_mask = lp.arc_mask | rp.arc_mask; piece.vertex_mask = lp.vertex_mask | rp.vertex_mask
			limit := (2*pop_count16(piece.vertex_mask) + 2) / 3
			if pop_count16(lp.vertex_mask) > limit || pop_count16(rp.vertex_mask) > limit || lp.vertex_mask & rp.vertex_mask == 0 do return false
		}
		expected: u16 = 0
		for v := 0; v < ctx.n; v += 1 {
			bit := u16(1) << u16(v)
			if piece.vertex_mask & bit == 0 do continue
			if v == ctx.source { expected |= bit; continue }
			for edge := 0; edge < ctx.m; edge += 1 {
				if piece.arc_mask & (u64(1) << u64(edge)) == 0 && (ctx.arcs[edge].tail == v || ctx.arcs[edge].head == v) { expected |= bit; break }
			}
		}
		if listed != expected || !piece_connected(ctx, piece.arc_mask, piece.vertex_mask) do return false
		if index == ctx.piece_count-1 && (piece.arc_mask != full || piece.vertex_mask != (u16(1)<<u16(ctx.n))-1) do return false
		ctx.pieces[index] = piece
	}
	if offset != int(length) || ctx.piece_count != 2*leaf_count-1 || leaf_union != full || parents[ctx.piece_count-1] != 0 do return false
	for i := 0; i < ctx.piece_count-1; i += 1 { if parents[i] != 1 do return false }
	root := ctx.pieces[ctx.piece_count-1]
	return root.boundary_count == 1 && root.boundary[0] == ctx.source
}

bellman :: proc (ctx: ^Context, nodes: [^]int, node_count: int, arcs: [^]Arc, arc_count: int, labels: [^]i64) -> bool {
	for v := 0; v < ctx.n; v += 1 { labels[v] = INF }
	for i := 0; i < node_count; i += 1 { labels[nodes[i]] = 0 }
	for pass := 0; pass < node_count-1; pass += 1 {
		changed := false
		for edge := 0; edge < arc_count; edge += 1 { a := arcs[edge]; candidate := labels[a.tail]+a.weight; if candidate < labels[a.head] { labels[a.head] = candidate; changed = true } }
		if !changed do break
	}
	for edge := 0; edge < arc_count; edge += 1 { a := arcs[edge]; if labels[a.tail]+a.weight < labels[a.head] do return false }
	return true
}

seeded :: proc (ctx: ^Context, arcs: [^]Arc, arc_count: int, seeds: [^]i64, labels: [^]i64) -> bool {
	for v := 0; v < ctx.n; v += 1 { labels[v] = seeds[v] }
	for pass := 0; pass < ctx.n-1; pass += 1 {
		changed := false
		for edge := 0; edge < arc_count; edge += 1 { a := arcs[edge]; if labels[a.tail] != INF && labels[a.tail]+a.weight < labels[a.head] { labels[a.head]=labels[a.tail]+a.weight; changed=true } }
		if !changed do break
	}
	for edge := 0; edge < arc_count; edge += 1 { a:=arcs[edge]; if labels[a.tail]!=INF && labels[a.tail]+a.weight<labels[a.head] do return false }
	return true
}

monge_sum :: proc "contextless" (a,b:i64) -> i64 { if a==INF || b==INF {return INF};return a+b }
check_monge :: proc (ctx:^Context,index,lo,hi:int) -> bool {
	if hi-lo<=1 do return true
	p:=ctx.pieces[index];middle:=(lo+hi)/2
	for direction:=0;direction<2;direction+=1 {
		rlo,rhi:=lo,middle;clo,chi:=middle,hi;if direction==1{rlo=middle;rhi=hi;clo=lo;chi=middle}
		for i:=rlo;i<rhi;i+=1{for i2:=i+1;i2<rhi;i2+=1{for j:=clo;j<chi;j+=1{for j2:=j+1;j2<chi;j2+=1{
			u,u2,v,v2:=p.boundary[i],p.boundary[i2],p.boundary[j],p.boundary[j2]
			if monge_sum(ctx.ddg[index][u][v],ctx.ddg[index][u2][v2])>monge_sum(ctx.ddg[index][u][v2],ctx.ddg[index][u2][v]) do return false
		}}}}
	}
	return check_monge(ctx,index,lo,middle)&&check_monge(ctx,index,middle,hi)
}

add_block :: proc (ctx:^Context,child:int,rows:[^]int,row_count:int,columns:[^]int,column_count:int,potential:[^]i64,blocks:[^]Block,count:^int) {
	if row_count==0||column_count==0||count^>=MAX_BLOCKS do return
	b:=&blocks[count^];count^+=1;b^=Block{};b.child=child;b.row_count=row_count;b.column_count=column_count
	for i:=0;i<row_count;i+=1{b.rows[i]=rows[i]};for j:=0;j<column_count;j+=1{b.columns[j]=columns[j]}
	for i:=0;i<row_count;i+=1{for j:=0;j<column_count;j+=1{u,v:=rows[i],columns[j];d:=ctx.ddg[child][u][v];if d==INF{b.weights[i][j]=INF}else{b.weights[i][j]=d+potential[u]-potential[v]}}}
}
build_blocks_rec :: proc (ctx:^Context,child,lo,hi:int,potential:[^]i64,blocks:[^]Block,count:^int) {
	if hi-lo<=1 do return
	p:=ctx.pieces[child];middle:=(lo+hi)/2
	add_block(ctx,child,&p.boundary[lo],middle-lo,&p.boundary[middle],hi-middle,potential,blocks,count)
	add_block(ctx,child,&p.boundary[middle],hi-middle,&p.boundary[lo],middle-lo,potential,blocks,count)
	build_blocks_rec(ctx,child,lo,middle,potential,blocks,count);build_blocks_rec(ctx,child,middle,hi,potential,blocks,count)
}

activate :: proc (vertex:int,value:i64,blocks:[^]Block,count:int,settled:[^]bool) {
	for bi:=0;bi<count;bi+=1{b:=&blocks[bi];for i:=0;i<b.row_count;i+=1{if b.rows[i]!=vertex do continue;for j:=0;j<b.column_count;j+=1{
		target:=b.columns[j];weight:=b.weights[i][j];if settled[target]||weight==INF do continue;candidate:=value+weight
		if candidate<b.best_value[j]||(candidate==b.best_value[j]&&vertex<b.best_row[j]){b.best_value[j]=candidate;b.best_row[j]=vertex}
	}}}
}
settle :: proc (vertex:int,settled:[^]bool,blocks:[^]Block,count:int) {
	settled[vertex]=true;for bi:=0;bi<count;bi+=1{for j:=0;j<blocks[bi].column_count;j+=1{if blocks[bi].columns[j]==vertex{blocks[bi].best_value[j]=INF;blocks[bi].best_row[j]=MAX_N}}}
}
dijkstra :: proc (ctx:^Context,nodes:[^]int,node_count:int,blocks:[^]Block,count:int,seeds:[^]i64,labels:[^]i64) {
	var settled:[MAX_N]bool;for v:=0;v<ctx.n;v+=1{labels[v]=INF};for bi:=0;bi<count;bi+=1{for j:=0;j<blocks[bi].column_count;j+=1{blocks[bi].best_value[j]=INF;blocks[bi].best_row[j]=MAX_N}}
	for i:=0;i<node_count;i+=1{v:=nodes[i];if seeds[v]<labels[v]{labels[v]=seeds[v]}}
	for i:=0;i<node_count;i+=1{v:=nodes[i];if labels[v]!=INF{activate(v,labels[v],blocks,count,&settled[0])}}
	for {
		best,best_row:=-1,MAX_N;best_value:=INF
		for i:=0;i<node_count;i+=1{v:=nodes[i];d:=labels[v];if !settled[v]&&d!=INF&&(d<best_value||(d==best_value&&v<best)){best=v;best_value=d;best_row=-1}}
		for bi:=0;bi<count;bi+=1{for j:=0;j<blocks[bi].column_count;j+=1{b:=&blocks[bi];v,row,d:=b.columns[j],b.best_row[j],b.best_value[j];if settled[v]||d==INF{continue};if d<best_value||(d==best_value&&(best<0||v<best))||(d==best_value&&v==best&&row<best_row){best=v;best_value=d;best_row=row}}}
		if best<0{break};if best_value<labels[best]{labels[best]=best_value};settle(best,&settled[0],blocks,count);activate(best,labels[best],blocks,count,&settled[0])
	}
}

collect_arcs :: proc (ctx:^Context,mask:u64,out:[^]Arc) -> int {count:=0;for e:=0;e<ctx.m;e+=1{if mask&(u64(1)<<u64(e))!=0{out[count]=ctx.arcs[e];count+=1}};return count}

build_piece :: proc (ctx:^Context,index:int,blocks:[^]Block) -> bool {
	p:=ctx.pieces[index];for u:=0;u<ctx.n;u+=1{for v:=0;v<ctx.n;v+=1{ctx.ddg[index][u][v]=INF}}
	if p.left==-1{var arcs:[3]Arc;arc_count:=collect_arcs(ctx,p.arc_mask,&arcs[0]);var nodes:[MAX_N]int;node_count:=0;for v:=0;v<ctx.n;v+=1{if p.vertex_mask&(u16(1)<<u16(v))!=0{nodes[node_count]=v;node_count+=1}};var potentials:[MAX_N]i64;if !bellman(ctx,&nodes[0],node_count,&arcs[0],arc_count,&potentials[0]){return false}
		for i:=0;i<p.boundary_count;i+=1{var seeds:[MAX_N]i64;var labels:[MAX_N]i64;for v:=0;v<ctx.n;v+=1{seeds[v]=INF};seeds[p.boundary[i]]=0;if !seeded(ctx,&arcs[0],arc_count,&seeds[0],&labels[0]){return false};for j:=0;j<p.boundary_count;j+=1{ctx.ddg[index][p.boundary[i]][p.boundary[j]]=labels[p.boundary[j]]}}
		return true
	}
	left,right:=p.left,p.right;var present:[MAX_N]bool;lp,rp:=ctx.pieces[left],ctx.pieces[right];for i:=0;i<lp.boundary_count;i+=1{present[lp.boundary[i]]=true};for i:=0;i<rp.boundary_count;i+=1{present[rp.boundary[i]]=true};var nodes:[MAX_N]int;node_count:=0;for v:=0;v<ctx.n;v+=1{if present[v]{nodes[node_count]=v;node_count+=1}}
	var union:[2*MAX_B*MAX_B]Arc;union_count:=0;for _,child in [2]int{left,right}{cp:=ctx.pieces[child];for i:=0;i<cp.boundary_count;i+=1{for j:=0;j<cp.boundary_count;j+=1{u,v:=cp.boundary[i],cp.boundary[j];d:=ctx.ddg[child][u][v];if u!=v&&d!=INF{union[union_count]=Arc{u,v,d};union_count+=1}}}}
	potential:=&ctx.potential[index][0];for v:=0;v<ctx.n;v+=1{potential[v]=0};if !bellman(ctx,&nodes[0],node_count,&union[0],union_count,potential){return false};for e:=0;e<union_count;e+=1{a:=union[e];if a.weight+potential[a.tail]-potential[a.head]<0{return false}}
	count:=0;for _,child in [2]int{left,right}{if !check_monge(ctx,child,0,ctx.pieces[child].boundary_count){return false};build_blocks_rec(ctx,child,0,ctx.pieces[child].boundary_count,potential,blocks,&count)};if count>MAX_BLOCKS{return false}
	for i:=0;i<p.boundary_count;i+=1{var seeds,labels:[MAX_N]i64;for v:=0;v<ctx.n;v+=1{seeds[v]=INF};seeds[p.boundary[i]]=0;dijkstra(ctx,&nodes[0],node_count,blocks,count,&seeds[0],&labels[0]);for j:=0;j<p.boundary_count;j+=1{u,v:=p.boundary[i],p.boundary[j];d:=labels[v];if d==INF{ctx.ddg[index][u][v]=INF}else{ctx.ddg[index][u][v]=d-potential[u]+potential[v]}}}
	return true
}

expand :: proc (ctx:^Context,index:int,known:[^]i64,result:[^]i64,blocks:[^]Block) {
	p:=ctx.pieces[index]
	if p.left==-1{var arcs:[3]Arc;count:=collect_arcs(ctx,p.arc_mask,&arcs[0]);var labels:[MAX_N]i64;if !seeded(ctx,&arcs[0],count,known,&labels[0]){return};for v:=0;v<ctx.n;v+=1{if p.vertex_mask&(u16(1)<<u16(v))!=0&&labels[v]<result[v]{result[v]=labels[v]}};return}
	left,right:=p.left,p.right;var present:[MAX_N]bool;for i:=0;i<ctx.pieces[left].boundary_count;i+=1{present[ctx.pieces[left].boundary[i]]=true};for i:=0;i<ctx.pieces[right].boundary_count;i+=1{present[ctx.pieces[right].boundary[i]]=true};var nodes:[MAX_N]int;node_count:=0;for v:=0;v<ctx.n;v+=1{if present[v]{nodes[node_count]=v;node_count+=1}}
	potential:=&ctx.potential[index][0];count:=0;build_blocks_rec(ctx,left,0,ctx.pieces[left].boundary_count,potential,blocks,&count);build_blocks_rec(ctx,right,0,ctx.pieces[right].boundary_count,potential,blocks,&count)
	var seeds,reduced,raw:[MAX_N]i64;for v:=0;v<ctx.n;v+=1{seeds[v]=INF;reduced[v]=INF;raw[v]=INF};for i:=0;i<p.boundary_count;i+=1{v:=p.boundary[i];if known[v]!=INF{seeds[v]=known[v]-potential[v]}};dijkstra(ctx,&nodes[0],node_count,blocks,count,&seeds[0],&reduced[0]);for v:=0;v<ctx.n;v+=1{if reduced[v]!=INF{raw[v]=reduced[v]+potential[v]}}
	for _,child in [2]int{left,right}{var child_known:[MAX_N]i64;for v:=0;v<ctx.n;v+=1{child_known[v]=INF};for i:=0;i<ctx.pieces[child].boundary_count;i+=1{v:=ctx.pieces[child].boundary[i];child_known[v]=raw[v]};expand(ctx,child,&child_known[0],result,blocks)}
}

put_i64_le :: proc "contextless" (output:[^]u8,offset:int,value:i64) {bits:=transmute(u64)value;for byte:=0;byte<8;byte+=1{output[offset+byte]=u8(bits>>u64(8*byte))}}

@(export)
fakcharoenphol_rao_planar_sssp :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
	var ctx:Context;if !parse(&ctx,input,length){return -1};var all_nodes:[MAX_N]int;for v:=0;v<ctx.n;v+=1{all_nodes[v]=v};var global_potential:[MAX_N]i64;if !bellman(&ctx,&all_nodes[0],ctx.n,&ctx.arcs[0],ctx.m,&global_potential[0]){return -1}
	var blocks:[MAX_BLOCKS]Block;for p:=0;p<ctx.piece_count;p+=1{if !build_piece(&ctx,p,&blocks[0]){return -1}}
	var result,known:[MAX_N]i64;for v:=0;v<ctx.n;v+=1{result[v]=INF;known[v]=INF};known[ctx.source]=0;expand(&ctx,ctx.piece_count-1,&known[0],&result[0],&blocks[0]);required:=ctx.n*8
	if output==nil||capacity<c.size_t(required){return -2};for v:=0;v<ctx.n;v+=1{value:=result[v];if value==INF{value=9223372036854775807};put_i64_le(output,v*8,value)};return i64(required)
}
