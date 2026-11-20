module fakcharoenphol_rao_planar_sssp

const max_n = 12
const max_m = 60
const max_p = 119
const max_b = 12
const max_blocks = 44
const max_input = 2088
const inf = i64(1152921504606846976)

struct FrArc { tail int; head int; weight i64 }
struct FrPiece { left int; right int; boundary_count int; arc_mask u64; vertex_mask u16; boundary [max_b]int }
struct FrBlock {
	child int
	row_count int
	column_count int
	rows [max_b]int
	columns [max_b]int
	weights [max_b][max_b]i64
	best_value [max_b]i64
	best_row [max_b]int
}
struct FrContext {
	n int
	m int
	source int
	piece_count int
	pieces [max_p]FrPiece
	arcs [max_m]FrArc
	ddg [max_p][max_n][max_n]i64
	potential [max_p][max_n]i64
}

fn pop16(value u16) int {
	mut v := value
	mut count := 0
	for v != 0 { count += int(v & 1); v >>= 1 }
	return count
}

fn pop64(value u64) int {
	mut v := value
	mut count := 0
	for v != 0 { count += int(v & 1); v >>= 1 }
	return count
}

fn vertex_mask(ctx &FrContext, mask u64) u16 {
	mut result := u16(0)
	for e in 0 .. ctx.m {
		if mask & (u64(1) << u64(e)) != 0 {
			result |= u16(1) << u16(ctx.arcs[e].tail)
			result |= u16(1) << u16(ctx.arcs[e].head)
		}
	}
	return result
}

fn piece_connected(ctx &FrContext, mask u64, vertices u16) bool {
	if vertices == 0 { return false }
	mut start := 0
	for vertices & (u16(1) << u16(start)) == 0 { start++ }
	mut reached := u16(1) << u16(start)
	mut changed := true
	for changed {
		changed = false
		for e in 0 .. ctx.m {
			if mask & (u64(1) << u64(e)) == 0 { continue }
			u := ctx.arcs[e].tail
			v := ctx.arcs[e].head
			ub := u16(1) << u16(u)
			vb := u16(1) << u16(v)
			if reached & ub != 0 && reached & vb == 0 { reached |= vb; changed = true }
			if reached & vb != 0 && reached & ub == 0 { reached |= ub; changed = true }
		}
	}
	return reached == vertices
}

fn parse(mut ctx FrContext, input &i64, length usize) bool {
	if unsafe { input == nil } || length < 4 || length > max_input { return false }
	unsafe {
		n0, m0, source0, piece_count0 := input[0], input[1], input[2], input[3]
		if n0 < 2 || n0 > max_n || m0 < 1 || m0 > max_m || source0 < 0 || source0 >= n0 || piece_count0 < 1 || piece_count0 > max_p || piece_count0 % 2 == 0 { return false }
		ctx.n = int(n0); ctx.m = int(m0); ctx.source = int(source0); ctx.piece_count = int(piece_count0)
		mut seen_arc := [max_n][max_n]bool{}
		mut seen_pair := [max_n][max_n]bool{}
		mut pair_count := 0
		mut offset := 4
		for e in 0 .. ctx.m {
			if offset + 3 > int(length) { return false }
			u0, v0, weight := input[offset], input[offset + 1], input[offset + 2]
			offset += 3
			if u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 || weight < -100 || weight > 100 { return false }
			u, v := int(u0), int(v0)
			if seen_arc[u][v] { return false }
			seen_arc[u][v] = true
			if !seen_pair[u][v] { seen_pair[u][v] = true; seen_pair[v][u] = true; pair_count++ }
			ctx.arcs[e] = FrArc{tail: u, head: v, weight: weight}
		}
		mut edge_limit := 3 * ctx.n - 6
		if ctx.n == 2 { edge_limit = 1 }
		if pair_count > edge_limit || ctx.m > 2 * edge_limit { return false }
		mut visited := [max_n]bool{}
		mut queue := [max_n]int{}
		mut head := 0
		mut tail := 1
		queue[0] = 0; visited[0] = true
		for head < tail {
			u := queue[head]; head++
			for e in 0 .. ctx.m {
				mut v := -1
				if ctx.arcs[e].tail == u { v = ctx.arcs[e].head }
				else if ctx.arcs[e].head == u { v = ctx.arcs[e].tail }
				if v >= 0 && !visited[v] { visited[v] = true; queue[tail] = v; tail++ }
			}
		}
		for v in 0 .. ctx.n { if !visited[v] { return false } }

		mut parents := [max_p]int{}
		mut leaf_union := u64(0)
		mut leaf_count := 0
		full := (u64(1) << u64(ctx.m)) - 1
		for index in 0 .. ctx.piece_count {
			if offset + 4 > int(length) { return false }
			left0, right0, mask0, bc0 := input[offset], input[offset + 1], input[offset + 2], input[offset + 3]
			offset += 4
			if bc0 < 1 || bc0 > n0 || bc0 > max_b || offset + int(bc0) > int(length) { return false }
			mut piece := FrPiece{left: int(left0), right: int(right0), boundary_count: int(bc0)}
			mut listed := u16(0)
			for j in 0 .. piece.boundary_count {
				v0 := input[offset]; offset++
				if v0 < 0 || v0 >= n0 { return false }
				v := int(v0); bit := u16(1) << u16(v)
				if listed & bit != 0 { return false }
				listed |= bit; piece.boundary[j] = v
			}
			if left0 == -1 && right0 == -1 {
				if mask0 <= 0 { return false }
				piece.arc_mask = u64(mask0)
				if piece.arc_mask & ~full != 0 || pop64(piece.arc_mask) > 3 || leaf_union & piece.arc_mask != 0 { return false }
				leaf_union |= piece.arc_mask; leaf_count++
				piece.vertex_mask = vertex_mask(ctx, piece.arc_mask)
				if !piece_connected(ctx, piece.arc_mask, piece.vertex_mask) { return false }
			} else {
				if left0 < 0 || right0 < 0 || left0 >= int64(index) || right0 >= int64(index) || left0 == right0 || mask0 != -1 { return false }
				left, right := int(left0), int(right0)
				if parents[left] != 0 || parents[right] != 0 { return false }
				parents[left] = 1; parents[right] = 1
				lp, rp := ctx.pieces[left], ctx.pieces[right]
				if lp.arc_mask & rp.arc_mask != 0 { return false }
				piece.arc_mask = lp.arc_mask | rp.arc_mask; piece.vertex_mask = lp.vertex_mask | rp.vertex_mask
				limit := (2 * pop16(piece.vertex_mask) + 2) / 3
				if pop16(lp.vertex_mask) > limit || pop16(rp.vertex_mask) > limit || lp.vertex_mask & rp.vertex_mask == 0 { return false }
			}
			mut expected := u16(0)
			for v in 0 .. ctx.n {
				bit := u16(1) << u16(v)
				if piece.vertex_mask & bit == 0 { continue }
				if v == ctx.source { expected |= bit; continue }
				for e in 0 .. ctx.m {
					if piece.arc_mask & (u64(1) << u64(e)) == 0 && (ctx.arcs[e].tail == v || ctx.arcs[e].head == v) { expected |= bit; break }
				}
			}
			if listed != expected || !piece_connected(ctx, piece.arc_mask, piece.vertex_mask) { return false }
			if index == ctx.piece_count - 1 && (piece.arc_mask != full || piece.vertex_mask != (u16(1) << u16(ctx.n)) - 1) { return false }
			ctx.pieces[index] = piece
		}
		if offset != int(length) || ctx.piece_count != 2 * leaf_count - 1 || leaf_union != full || parents[ctx.piece_count - 1] != 0 { return false }
		for i in 0 .. ctx.piece_count - 1 { if parents[i] != 1 { return false } }
		root := ctx.pieces[ctx.piece_count - 1]
		return root.boundary_count == 1 && root.boundary[0] == ctx.source
	}
}

fn bellman(ctx &FrContext, nodes []int, arcs []FrArc, mut labels [max_n]i64) bool {
	for v in 0 .. ctx.n { labels[v] = inf }
	for v in nodes { labels[v] = 0 }
	for _ in 0 .. max(0, nodes.len - 1) {
		mut changed := false
		for a in arcs { candidate := labels[a.tail] + a.weight; if candidate < labels[a.head] { labels[a.head] = candidate; changed = true } }
		if !changed { break }
	}
	for a in arcs { if labels[a.tail] + a.weight < labels[a.head] { return false } }
	return true
}

fn seeded(ctx &FrContext, arcs []FrArc, seeds [max_n]i64, mut labels [max_n]i64) bool {
	for v in 0 .. ctx.n { labels[v] = seeds[v] }
	for _ in 0 .. ctx.n - 1 {
		mut changed := false
		for a in arcs { if labels[a.tail] != inf && labels[a.tail] + a.weight < labels[a.head] { labels[a.head] = labels[a.tail] + a.weight; changed = true } }
		if !changed { break }
	}
	for a in arcs { if labels[a.tail] != inf && labels[a.tail] + a.weight < labels[a.head] { return false } }
	return true
}

fn monge_sum(a i64, b i64) i64 { if a == inf || b == inf { return inf }; return a + b }

fn check_monge(ctx &FrContext, index int, lo int, hi int) bool {
	if hi - lo <= 1 { return true }
	piece := ctx.pieces[index]; middle := (lo + hi) / 2
	for direction in 0 .. 2 {
		rlo, rhi, clo, chi := lo, middle, middle, hi
		if direction == 1 { rlo, rhi, clo, chi = middle, hi, lo, middle }
		for i in rlo .. rhi { for i2 in i + 1 .. rhi { for j in clo .. chi { for j2 in j + 1 .. chi {
			u, u2, v, v2 := piece.boundary[i], piece.boundary[i2], piece.boundary[j], piece.boundary[j2]
			if monge_sum(ctx.ddg[index][u][v], ctx.ddg[index][u2][v2]) > monge_sum(ctx.ddg[index][u][v2], ctx.ddg[index][u2][v]) { return false }
		} } } }
	}
	return check_monge(ctx,index,lo,middle) && check_monge(ctx,index,middle,hi)
}

fn add_block(ctx &FrContext, child int, rows []int, columns []int, potential [max_n]i64, mut blocks []FrBlock) {
	if rows.len == 0 || columns.len == 0 { return }
	mut block := FrBlock{child: child, row_count: rows.len, column_count: columns.len}
	for i, v in rows { block.rows[i] = v }
	for j, v in columns { block.columns[j] = v }
	for i, u in rows { for j, v in columns { d := ctx.ddg[child][u][v]; if d == inf { block.weights[i][j] = inf } else { block.weights[i][j] = d + potential[u] - potential[v] } } }
	blocks << block
}

fn build_blocks_rec(ctx &FrContext, child int, lo int, hi int, potential [max_n]i64, mut blocks []FrBlock) {
	if hi - lo <= 1 { return }
	p := ctx.pieces[child]; middle := (lo + hi) / 2
	add_block(ctx, child, p.boundary[lo..middle], p.boundary[middle..hi], potential, mut blocks)
	add_block(ctx, child, p.boundary[middle..hi], p.boundary[lo..middle], potential, mut blocks)
	build_blocks_rec(ctx, child, lo, middle, potential, mut blocks)
	build_blocks_rec(ctx, child, middle, hi, potential, mut blocks)
}

fn activate(vertex int, value i64, mut blocks []FrBlock, settled [max_n]bool) {
	for mut block in blocks {
		for i in 0 .. block.row_count {
			if block.rows[i] != vertex { continue }
			for j in 0 .. block.column_count {
				target := block.columns[j]; weight := block.weights[i][j]
				if settled[target] || weight == inf { continue }
				candidate := value + weight
				if candidate < block.best_value[j] || (candidate == block.best_value[j] && vertex < block.best_row[j]) { block.best_value[j] = candidate; block.best_row[j] = vertex }
			}
		}
	}
}

fn settle(vertex int, mut settled [max_n]bool, mut blocks []FrBlock) {
	settled[vertex] = true
	for mut block in blocks { for j in 0 .. block.column_count { if block.columns[j] == vertex { block.best_value[j] = inf; block.best_row[j] = max_n } } }
}

fn dijkstra(ctx &FrContext, nodes []int, mut blocks []FrBlock, seeds [max_n]i64, mut labels [max_n]i64) {
	mut settled := [max_n]bool{}
	for v in 0 .. ctx.n { labels[v] = inf }
	for mut block in blocks { for j in 0 .. block.column_count { block.best_value[j] = inf; block.best_row[j] = max_n } }
	for v in nodes { if seeds[v] < labels[v] { labels[v] = seeds[v] } }
	for v in nodes { if labels[v] != inf { activate(v, labels[v], mut blocks, settled) } }
	for {
		mut best := -1; mut best_row := max_n; mut best_value := inf
		for v in nodes { if !settled[v] && labels[v] != inf && (labels[v] < best_value || (labels[v] == best_value && v < best)) { best = v; best_value = labels[v]; best_row = -1 } }
		for block in blocks { for j in 0 .. block.column_count {
			v := block.columns[j]; value := block.best_value[j]; row := block.best_row[j]
			if settled[v] || value == inf { continue }
			if value < best_value || (value == best_value && (best < 0 || v < best)) || (value == best_value && v == best && row < best_row) { best = v; best_value = value; best_row = row }
		} }
		if best < 0 { break }
		if best_value < labels[best] { labels[best] = best_value }
		settle(best, mut settled, mut blocks)
		activate(best, labels[best], mut blocks, settled)
	}
}

fn collect_arcs(ctx &FrContext, mask u64, mut arcs [3]FrArc) int {
	mut count := 0
	for e in 0 .. ctx.m { if mask & (u64(1) << u64(e)) != 0 { arcs[count] = ctx.arcs[e]; count++ } }
	return count
}

fn build_piece(mut ctx FrContext, index int, mut blocks []FrBlock) bool {
	p := ctx.pieces[index]
	for u in 0 .. ctx.n { for v in 0 .. ctx.n { ctx.ddg[index][u][v] = inf } }
	if p.left == -1 {
		mut arcs := [3]FrArc{}
		arc_count := collect_arcs(ctx, p.arc_mask, mut arcs)
		mut nodes := []int{}
		for v in 0 .. ctx.n { if p.vertex_mask & (u16(1) << u16(v)) != 0 { nodes << v } }
		mut potential := [max_n]i64{}
		if !bellman(ctx, nodes, arcs[..arc_count], mut potential) { return false }
		for i in 0 .. p.boundary_count {
			mut seeds := [max_n]i64{}; mut labels := [max_n]i64{}
			for v in 0 .. ctx.n { seeds[v] = inf }
			seeds[p.boundary[i]] = 0
			if !seeded(ctx, arcs[..arc_count], seeds, mut labels) { return false }
			for j in 0 .. p.boundary_count { ctx.ddg[index][p.boundary[i]][p.boundary[j]] = labels[p.boundary[j]] }
		}
		return true
	}
	left, right := p.left, p.right
	mut nodes_set := [max_n]bool{}
	for v in ctx.pieces[left].boundary[..ctx.pieces[left].boundary_count] { nodes_set[v] = true }
	for v in ctx.pieces[right].boundary[..ctx.pieces[right].boundary_count] { nodes_set[v] = true }
	mut nodes := []int{}
	for v in 0 .. ctx.n { if nodes_set[v] { nodes << v } }
	mut union_arcs := []FrArc{}
	for child in [left, right] { cp := ctx.pieces[child]; for u in cp.boundary[..cp.boundary_count] { for v in cp.boundary[..cp.boundary_count] { d := ctx.ddg[child][u][v]; if u != v && d != inf { union_arcs << FrArc{tail:u,head:v,weight:d} } } } }
	mut potential := [max_n]i64{}
	if !bellman(ctx, nodes, union_arcs, mut potential) { return false }
	ctx.potential[index] = potential
	for a in union_arcs { if a.weight + potential[a.tail] - potential[a.head] < 0 { return false } }
	mut local_blocks := []FrBlock{}
	for child in [left, right] { if !check_monge(ctx,child,0,ctx.pieces[child].boundary_count) { return false }; build_blocks_rec(ctx,child,0,ctx.pieces[child].boundary_count,potential,mut local_blocks) }
	if local_blocks.len > max_blocks { return false }
	for i in 0 .. p.boundary_count {
		mut seeds := [max_n]i64{}; mut labels := [max_n]i64{}; for v in 0 .. ctx.n { seeds[v] = inf }; seeds[p.boundary[i]] = 0
		dijkstra(ctx,nodes,mut local_blocks,seeds,mut labels)
		for j in 0 .. p.boundary_count { s:=p.boundary[i];t:=p.boundary[j];d:=labels[t];ctx.ddg[index][s][t]=if d==inf{inf}else{d-potential[s]+potential[t]} }
	}
	return true
}

fn expand(mut ctx FrContext, index int, known [max_n]i64, mut result [max_n]i64) {
	p := ctx.pieces[index]
	if p.left == -1 {
		mut arcs := [3]FrArc{}; arc_count := collect_arcs(ctx,p.arc_mask,mut arcs); mut labels := [max_n]i64{}
		if !seeded(ctx,arcs[..arc_count],known,mut labels) { return }
		for v in 0 .. ctx.n { if p.vertex_mask & (u16(1)<<u16(v)) != 0 && labels[v] < result[v] { result[v] = labels[v] } }
		return
	}
	left,right:=p.left,p.right;mut nodes_set:=[max_n]bool{}
	for v in ctx.pieces[left].boundary[..ctx.pieces[left].boundary_count]{nodes_set[v]=true};for v in ctx.pieces[right].boundary[..ctx.pieces[right].boundary_count]{nodes_set[v]=true}
	mut nodes:=[]int{};for v in 0..ctx.n{if nodes_set[v]{nodes<<v}}
	mut blocks:=[]FrBlock{};build_blocks_rec(ctx,left,0,ctx.pieces[left].boundary_count,ctx.potential[index],mut blocks);build_blocks_rec(ctx,right,0,ctx.pieces[right].boundary_count,ctx.potential[index],mut blocks)
	mut seeds:=[max_n]i64{};for v in 0..ctx.n{seeds[v]=inf};for v in p.boundary[..p.boundary_count]{if known[v]!=inf{seeds[v]=known[v]-ctx.potential[index][v]}}
	mut reduced:=[max_n]i64{};dijkstra(ctx,nodes,mut blocks,seeds,mut reduced);mut raw:=[max_n]i64{};for v in 0..ctx.n{if reduced[v]!=inf{raw[v]=reduced[v]+ctx.potential[index][v]}else{raw[v]=inf}}
	for child in [left,right]{mut child_known:=[max_n]i64{};for v in 0..ctx.n{child_known[v]=inf};for v in ctx.pieces[child].boundary[..ctx.pieces[child].boundary_count]{child_known[v]=raw[v]};expand(mut ctx,child,child_known,mut result)}
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'fakcharoenphol_rao_planar_sssp']
pub fn fakcharoenphol_rao_planar_sssp(input &i64, length usize, mut output &u8, capacity usize) i64 {
	mut ctx := FrContext{}
	if !parse(mut ctx,input,length) { return -1 }
	mut all_nodes := []int{}
	for v in 0 .. ctx.n { all_nodes << v }
	mut global_potential := [max_n]i64{}
	if !bellman(ctx,all_nodes,ctx.arcs[..ctx.m],mut global_potential) { return -1 }
	mut blocks := []FrBlock{}
	for p in 0 .. ctx.piece_count { if !build_piece(mut ctx,p,mut blocks) { return -1 } }
	mut result := [max_n]i64{}
	mut known := [max_n]i64{}
	for v in 0 .. ctx.n { result[v]=inf;known[v]=inf }
	known[ctx.source]=0
	expand(mut ctx,ctx.piece_count-1,known,mut result)
	required := ctx.n * 8
	if unsafe { output == nil } || capacity < usize(required) { return -2 }
	for v in 0 .. ctx.n { value:=result[v];if value==inf{value=9223372036854775807};put_i64_le(mut output,v*8,value) }
	return i64(required)
}
