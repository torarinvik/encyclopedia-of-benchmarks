module dynamic_graph_vertex_add_component_sum

const max_n = 16
const max_q = 32
const max_ops = max_n + 2 * max_q
const tree_nodes = 4 * max_q + 8

fn root_of(parent []int, input_vertex int) int {
	mut v := input_vertex
	for parent[v] != v { v = parent[v] }
	return v
}

fn place(node int, left int, right int, ql int, qr int, id int,
	mut count []int, mut bucket []int) {
	if ql <= left && right <= qr {
		bucket[node * max_ops + count[node]] = id
		count[node]++
		return
	}
	mid := left + (right - left) / 2
	if ql < mid { place(node * 2, left, mid, ql, qr, id, mut count, mut bucket) }
	if qr > mid { place(node * 2 + 1, mid, right, ql, qr, id, mut count, mut bucket) }
}

fn unite(u int, v int, mut parent []int, mut size []int, mut total []i64,
	mut hist_kind []int, mut hist_a []int, mut hist_b []int, mut hist_size []int,
	mut hist_sum []i64, mut hist_len int) {
	mut ru := root_of(parent, u)
	mut rv := root_of(parent, v)
	if ru == rv { return }
	if size[ru] < size[rv] || (size[ru] == size[rv] && ru > rv) { ru, rv = rv, ru }
	hist_kind[hist_len] = 0
	hist_a[hist_len] = rv
	hist_b[hist_len] = ru
	hist_size[hist_len] = size[ru]
	hist_sum[hist_len] = total[ru]
	hist_len++
	parent[rv] = ru
	size[ru] += size[rv]
	total[ru] += total[rv]
}

fn add_value(v int, delta i64, parent []int, mut total []i64,
	mut hist_kind []int, mut hist_a []int, mut hist_sum []i64, mut hist_len int) {
	r := root_of(parent, v)
	hist_kind[hist_len] = 1
	hist_a[hist_len] = r
	hist_sum[hist_len] = total[r]
	hist_len++
	total[r] += delta
}

fn rollback(mark int, mut parent []int, mut size []int, mut total []i64,
	hist_kind []int, hist_a []int, hist_b []int, hist_size []int, hist_sum []i64,
	mut hist_len int) {
	for hist_len > mark {
		hist_len--
		k := hist_kind[hist_len]
		a := hist_a[hist_len]
		if k == 0 {
			r := hist_b[hist_len]
			parent[a] = a
			size[r] = hist_size[hist_len]
			total[r] = hist_sum[hist_len]
		} else { total[a] = hist_sum[hist_len] }
	}
}

fn visit(node int, left int, right int, op_kind []int, op_a []int, op_b []int,
	op_delta []i64, count []int, bucket []int, event_op []i64, event_a []i64,
	mut parent []int, mut size []int, mut total []i64, mut hist_kind []int,
	mut hist_a []int, mut hist_b []int, mut hist_size []int, mut hist_sum []i64,
	mut hist_len int, mut answer []i64) {
	mark := hist_len
	for i in 0 .. count[node] {
		id := bucket[node * max_ops + i]
		if op_kind[id] == 0 {
			unite(op_a[id], op_b[id], mut parent, mut size, mut total, mut hist_kind,
				mut hist_a, mut hist_b, mut hist_size, mut hist_sum, mut hist_len)
		} else {
			add_value(op_a[id], op_delta[id], parent, mut total, mut hist_kind,
				mut hist_a, mut hist_sum, mut hist_len)
		}
	}
	if right - left == 1 {
		if event_op[left] == 3 { answer[left] = total[root_of(parent, int(event_a[left]))] }
	} else {
		mid := left + (right - left) / 2
		visit(node * 2, left, mid, op_kind, op_a, op_b, op_delta, count, bucket,
			event_op, event_a, mut parent, mut size, mut total, mut hist_kind,
			mut hist_a, mut hist_b, mut hist_size, mut hist_sum, mut hist_len, mut answer)
		visit(node * 2 + 1, mid, right, op_kind, op_a, op_b, op_delta, count, bucket,
			event_op, event_a, mut parent, mut size, mut total, mut hist_kind,
			mut hist_a, mut hist_b, mut hist_size, mut hist_sum, mut hist_len, mut answer)
	}
	rollback(mark, mut parent, mut size, mut total, hist_kind, hist_a, hist_b,
		hist_size, hist_sum, mut hist_len)
}

fn store_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for i in 0 .. 8 { output[offset + i] = u8(bits >> (8 * i)) } }
}

@[export: 'dynamic_graph_vertex_add_component_sum']
pub fn dynamic_graph_vertex_add_component_sum(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(2 + max_n + 3 * max_q + 1) { return -1 }
	nv := unsafe { input[0] }
	qv := unsafe { input[1] }
	if nv < 1 || nv > max_n || qv < 0 || qv > max_q { return -1 }
	n := int(nv)
	q := int(qv)
	if length != usize(2 + n + 3 * q) { return -1 }
	mut initial := []i64{len: max_n}
	for v in 0 .. n { initial[v] = unsafe { input[2 + v] }; if initial[v] < 0 || initial[v] > 100 { return -1 } }
	mut event_op := []i64{len: max_q}
	mut event_a := []i64{len: max_q}
	mut event_b := []i64{len: max_q}
	mut active := []bool{len: max_n * max_n}
	mut start := []int{len: max_n * max_n}
	mut op_kind := []int{len: max_ops}
	mut op_a := []int{len: max_ops}
	mut op_b := []int{len: max_ops}
	mut op_delta := []i64{len: max_ops}
	mut il := []int{len: max_ops}
	mut ir := []int{len: max_ops}
	mut op_count := 0
	mut query_count := 0
	for t in 0 .. q {
		off := 2 + n + 3 * t
		op := unsafe { input[off] }; a := unsafe { input[off + 1] }; b := unsafe { input[off + 2] }
		event_op[t] = op; event_a[t] = a; event_b[t] = b
		if op == 0 || op == 1 {
			if a < 0 || a >= nv || b < 0 || b >= nv || a == b { return -1 }
			mut u := int(a); mut v := int(b); if u > v { u, v = v, u }
			ix := u * max_n + v
			if op == 0 { if active[ix] { return -1 }; active[ix] = true; start[ix] = t }
			else { if !active[ix] { return -1 }; active[ix] = false; if start[ix] < t { op_kind[op_count] = 0; op_a[op_count] = u; op_b[op_count] = v; il[op_count] = start[ix]; ir[op_count] = t; op_count++ } }
		} else if op == 2 {
			if a < 0 || a >= nv || b < 0 || b > 100 { return -1 }
			if b != 0 && t < q { op_kind[op_count] = 1; op_a[op_count] = int(a); op_delta[op_count] = b; il[op_count] = t; ir[op_count] = q; op_count++ }
		} else if op == 3 { if a < 0 || a >= nv || b != 0 { return -1 }; query_count++ }
		else { return -1 }
	}
	for u in 0 .. n { for v in u + 1 .. n { ix := u * max_n + v; if active[ix] && start[ix] < q { op_kind[op_count] = 0; op_a[op_count] = u; op_b[op_count] = v; il[op_count] = start[ix]; ir[op_count] = q; op_count++ } } }
	if q > 0 { for v in 0 .. n { if initial[v] != 0 { op_kind[op_count] = 1; op_a[op_count] = v; op_delta[op_count] = initial[v]; il[op_count] = 0; ir[op_count] = q; op_count++ } } }
	if unsafe { output == nil } || capacity < usize(8 * query_count) { return -2 }
	mut count := []int{len: tree_nodes}
	mut bucket := []int{len: tree_nodes * max_ops}
	if q > 0 { for i in 0 .. op_count { if il[i] < ir[i] { place(1, 0, q, il[i], ir[i], i, mut count, mut bucket) } } }
	mut parent := []int{len: max_n}; mut size := []int{len: max_n}; mut total := []i64{len: max_n}
	for v in 0 .. n { parent[v] = v; size[v] = 1 }
	mut hk := []int{len: max_ops}; mut ha := []int{len: max_ops}; mut hb := []int{len: max_ops}; mut hs := []int{len: max_ops}; mut hv := []i64{len: max_ops}; mut hl := 0
	mut answer := []i64{len: max_q}
	if q > 0 { visit(1, 0, q, op_kind, op_a, op_b, op_delta, count, bucket, event_op, event_a, mut parent, mut size, mut total, mut hk, mut ha, mut hb, mut hs, mut hv, mut hl, mut answer) }
	mut written := 0
	for t in 0 .. q { if event_op[t] == 3 { store_le(mut output, written, answer[t]); written += 8 } }
	return i64(written)
}
