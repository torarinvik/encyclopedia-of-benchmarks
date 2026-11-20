module measured_finger_tree_sequence

const ft_max_q = 32
const ft_max_roots = 65
const ft_arena = 16384
const ft_levels = 16
const ft_pool = 8192
const ft_max_input = 194
const ft_max_parseable = 195
const ft_max_value = i64(1000000)
const ft_max_length = 64
const ft_max_sum = i64(64000000)

struct FtObject {
	kind u8
	level u8
	plen u8
	slen u8
	arity u8
	mid i32
	refs [8]i32
	count i32
	sum i64
}

struct FtContext {
	objects [ft_arena]FtObject
	used usize
	empty_id [ft_levels]i32
	empty_ready [ft_levels]bool
	failed bool
}

struct FtRoot {
	tree i32
	length i32
	sum i64
}

struct FtView {
	found bool
	item i32
	tree i32
}

struct FtSplit {
	found bool
	item i32
	left i32
	right i32
}

struct FtMeasure {
	count i32
	sum i64
}

fn ft_add(a FtMeasure, b FtMeasure) FtMeasure {
	return FtMeasure{count: a.count + b.count, sum: a.sum + b.sum}
}

fn ft_ref_measure(c &FtContext, ref i32) FtMeasure {
	if ref < 0 { return FtMeasure{count: 1, sum: -i64(ref) - 1} }
	obj := c.objects[int(ref)]
	return FtMeasure{count: obj.count, sum: obj.sum}
}

fn ft_tree_measure(c &FtContext, id i32) FtMeasure {
	obj := c.objects[int(id)]
	return FtMeasure{count: obj.count, sum: obj.sum}
}

fn ft_alloc(mut c &FtContext) i32 {
	if c.used >= ft_arena || c.used >= ft_pool * 2 {
		c.failed = true
		return 0
	}
	id := i32(c.used)
	c.used++
	c.objects[int(id)] = FtObject{}
	return id
}

fn ft_empty(mut c &FtContext, level u8) i32 {
	if level >= ft_levels { c.failed = true; return 0 }
	if c.empty_ready[level] { return c.empty_id[level] }
	id := ft_alloc(mut c)
	c.objects[int(id)].kind = 0
	c.objects[int(id)].level = level
	c.objects[int(id)].mid = -1
	c.empty_id[level] = id
	c.empty_ready[level] = true
	return id
}

fn ft_single(mut c &FtContext, level u8, item i32) i32 {
	id := ft_alloc(mut c)
	mut obj := &c.objects[int(id)]
	obj.kind = 1
	obj.level = level
	obj.plen = 1
	obj.refs[0] = item
	m := ft_ref_measure(c, item)
	obj.count = m.count
	obj.sum = m.sum
	return id
}

fn ft_node(mut c &FtContext, child_level u8, items [3]i32, arity u8) i32 {
	id := ft_alloc(mut c)
	mut obj := &c.objects[int(id)]
	obj.kind = 3
	obj.level = child_level + 1
	obj.arity = arity
	mut measure := FtMeasure{}
	for i in 0 .. int(arity) {
		obj.refs[i] = items[i]
		measure = ft_add(measure, ft_ref_measure(c, items[i]))
	}
	obj.count = measure.count
	obj.sum = measure.sum
	return id
}

fn ft_deep(mut c &FtContext, level u8, pre [4]i32, plen u8, mid i32, suf [4]i32, slen u8) i32 {
	if plen == 0 || slen == 0 { c.failed = true; return ft_empty(mut c, level) }
	id := ft_alloc(mut c)
	mut obj := &c.objects[int(id)]
	obj.kind = 2
	obj.level = level
	obj.plen = plen
	obj.slen = slen
	obj.mid = mid
	measure := ft_tree_measure(c, mid)
	mut total := measure
	for i in 0 .. int(plen) { obj.refs[i] = pre[i]; total = ft_add(total, ft_ref_measure(c, pre[i])) }
	for i in 0 .. int(slen) { obj.refs[4+i] = suf[i]; total = ft_add(total, ft_ref_measure(c, suf[i])) }
	obj.count = total.count
	obj.sum = total.sum
	return id
}

fn ft_from_items(mut c &FtContext, level u8, items [16]i32, count u8) i32 {
	mut out := ft_empty(mut c, level)
	for i in 0 .. int(count) { out = ft_snoc(mut c, level, out, items[i]) }
	return out
}

fn ft_cons(mut c &FtContext, level u8, item i32, id i32) i32 {
	t := c.objects[int(id)]
	if t.kind == 0 { return ft_single(mut c, level, item) }
	if t.kind == 1 {
		mut pre := [4]i32{}; mut suf := [4]i32{}
		pre[0] = item; suf[0] = t.refs[0]
		return ft_deep(mut c, level, pre, 1, ft_empty(mut c, level + 1), suf, 1)
	}
	if t.plen < 4 {
		mut pre := [4]i32{}; pre[0] = item
		for i in 0 .. int(t.plen) { pre[i+1] = t.refs[i] }
		mut suf := [4]i32{}; for i in 0 .. int(t.slen) { suf[i] = t.refs[4+i] }
		return ft_deep(mut c, level, pre, t.plen + 1, t.mid, suf, t.slen)
	}
	group := [3]i32{t.refs[1], t.refs[2], t.refs[3]}
	middle := ft_cons(mut c, level + 1, ft_node(mut c, level, group, 3), t.mid)
	mut pre := [4]i32{}; pre[0] = item; pre[1] = t.refs[0]
	mut suf := [4]i32{}; for i in 0 .. int(t.slen) { suf[i] = t.refs[4+i] }
	return ft_deep(mut c, level, pre, 2, middle, suf, t.slen)
}

fn ft_snoc(mut c &FtContext, level u8, id i32, item i32) i32 {
	t := c.objects[int(id)]
	if t.kind == 0 { return ft_single(mut c, level, item) }
	if t.kind == 1 {
		mut pre := [4]i32{}; mut suf := [4]i32{}
		pre[0] = t.refs[0]; suf[0] = item
		return ft_deep(mut c, level, pre, 1, ft_empty(mut c, level + 1), suf, 1)
	}
	if t.slen < 4 {
		mut pre := [4]i32{}; for i in 0 .. int(t.plen) { pre[i] = t.refs[i] }
		mut suf := [4]i32{}; for i in 0 .. int(t.slen) { suf[i] = t.refs[4+i] }; suf[t.slen] = item
		return ft_deep(mut c, level, pre, t.plen, t.mid, suf, t.slen + 1)
	}
	group := [3]i32{t.refs[4], t.refs[5], t.refs[6]}
	middle := ft_snoc(mut c, level + 1, t.mid, ft_node(mut c, level, group, 3))
	mut pre := [4]i32{}; for i in 0 .. int(t.plen) { pre[i] = t.refs[i] }
	mut suf := [4]i32{t.refs[7], item}
	return ft_deep(mut c, level, pre, t.plen, middle, suf, 2)
}

fn ft_view_left(mut c &FtContext, level u8, id i32) FtView {
	t := c.objects[int(id)]
	if t.kind == 0 { return FtView{found: false, item: 0, tree: id} }
	if t.kind == 1 { return FtView{found: true, item: t.refs[0], tree: ft_empty(mut c, level)} }
	item := t.refs[0]
	mut rest := i32(0)
	if t.plen > 1 {
		mut pre := [4]i32{}; for i in 1 .. int(t.plen) { pre[i-1] = t.refs[i] }
		mut suf := [4]i32{}; for i in 0 .. int(t.slen) { suf[i] = t.refs[4+i] }
		rest = ft_deep(mut c, level, pre, t.plen - 1, t.mid, suf, t.slen)
	} else {
		view := ft_view_left(mut c, level + 1, t.mid)
		if !view.found {
			mut suffix := [16]i32{}; for i in 0 .. int(t.slen) { suffix[i] = t.refs[4+i] }
			rest = ft_from_items(mut c, level, suffix, t.slen)
		} else {
			node := c.objects[int(view.item)]
			mut pre := [4]i32{}; for i in 0 .. int(node.arity) { pre[i] = node.refs[i] }
			mut suf := [4]i32{}; for i in 0 .. int(t.slen) { suf[i] = t.refs[4+i] }
			rest = ft_deep(mut c, level, pre, node.arity, view.tree, suf, t.slen)
		}
	}
	return FtView{found: true, item: item, tree: rest}
}

fn ft_view_right(mut c &FtContext, level u8, id i32) FtView {
	t := c.objects[int(id)]
	if t.kind == 0 { return FtView{found: false, item: 0, tree: id} }
	if t.kind == 1 { return FtView{found: true, item: t.refs[0], tree: ft_empty(mut c, level)} }
	item := t.refs[4 + int(t.slen) - 1]
	mut rest := i32(0)
	if t.slen > 1 {
		mut pre := [4]i32{}; for i in 0 .. int(t.plen) { pre[i] = t.refs[i] }
		mut suf := [4]i32{}; for i in 0 .. int(t.slen)-1 { suf[i] = t.refs[4+i] }
		rest = ft_deep(mut c, level, pre, t.plen, t.mid, suf, t.slen - 1)
	} else {
		view := ft_view_right(mut c, level + 1, t.mid)
		if !view.found {
			mut prefix := [16]i32{}; for i in 0 .. int(t.plen) { prefix[i] = t.refs[i] }
			rest = ft_from_items(mut c, level, prefix, t.plen)
		} else {
			node := c.objects[int(view.item)]
			mut pre := [4]i32{}; for i in 0 .. int(t.plen) { pre[i] = t.refs[i] }
			mut suf := [4]i32{}; for i in 0 .. int(node.arity) { suf[i] = node.refs[i] }
			rest = ft_deep(mut c, level, pre, t.plen, view.tree, suf, node.arity)
		}
	}
	return FtView{found: true, item: item, tree: rest}
}

fn ft_deep_left(mut c &FtContext, level u8, pre [4]i32, plen u8, mid i32, suf [4]i32, slen u8) i32 {
	if plen > 0 { return ft_deep(mut c, level, pre, plen, mid, suf, slen) }
	view := ft_view_left(mut c, level + 1, mid)
	if !view.found {
		mut items := [16]i32{}; for i in 0 .. int(slen) { items[i] = suf[i] }
		return ft_from_items(mut c, level, items, slen)
	}
	node := c.objects[int(view.item)]
	mut next_pre := [4]i32{}; for i in 0 .. int(node.arity) { next_pre[i] = node.refs[i] }
	return ft_deep(mut c, level, next_pre, node.arity, view.tree, suf, slen)
}

fn ft_deep_right(mut c &FtContext, level u8, pre [4]i32, plen u8, mid i32, suf [4]i32, slen u8) i32 {
	if slen > 0 { return ft_deep(mut c, level, pre, plen, mid, suf, slen) }
	view := ft_view_right(mut c, level + 1, mid)
	if !view.found {
		mut items := [16]i32{}; for i in 0 .. int(plen) { items[i] = pre[i] }
		return ft_from_items(mut c, level, items, plen)
	}
	node := c.objects[int(view.item)]
	mut next_suf := [4]i32{}; for i in 0 .. int(node.arity) { next_suf[i] = node.refs[i] }
	return ft_deep(mut c, level, pre, plen, view.tree, next_suf, node.arity)
}

fn ft_group_items(mut c &FtContext, level u8, items [16]i32, n int, mut out [8]i32) int {
	mut used := 0
	mut pos := 0
	for pos < n {
		rem := n - pos
		take := if rem == 2 || rem == 4 { 2 } else { 3 }
		if rem == 1 { c.failed = true; return used }
		mut children := [3]i32{}
		for i in 0 .. take { children[i] = items[pos+i] }
		out[used] = ft_node(mut c, level, children, u8(take))
		used++
		pos += take
	}
	return used
}

fn ft_append3(mut c &FtContext, level u8, left i32, bridge [16]i32, bridge_count u8, right i32) i32 {
	a := c.objects[int(left)]
	b := c.objects[int(right)]
	if a.kind == 0 {
		mut out := right
		for i := int(bridge_count) - 1; i >= 0; i-- { out = ft_cons(mut c, level, bridge[i], out) }
		return out
	}
	if b.kind == 0 {
		mut out := left
		for i in 0 .. int(bridge_count) { out = ft_snoc(mut c, level, out, bridge[i]) }
		return out
	}
	if a.kind == 1 {
		mut out := right
		for i := int(bridge_count) - 1; i >= 0; i-- { out = ft_cons(mut c, level, bridge[i], out) }
		return ft_cons(mut c, level, a.refs[0], out)
	}
	if b.kind == 1 {
		mut out := left
		for i in 0 .. int(bridge_count) { out = ft_snoc(mut c, level, out, bridge[i]) }
		return ft_snoc(mut c, level, out, b.refs[0])
	}
	mut combined := [16]i32{}
	mut count := 0
	for i in 0 .. int(a.slen) { combined[count] = a.refs[4+i]; count++ }
	for i in 0 .. int(bridge_count) { combined[count] = bridge[i]; count++ }
	for i in 0 .. int(b.plen) { combined[count] = b.refs[i]; count++ }
	mut groups := [8]i32{}
	group_count := ft_group_items(mut c, level, combined, count, mut groups)
	mut bridge_nodes := [16]i32{}
	for i in 0 .. group_count { bridge_nodes[i] = groups[i] }
	middle := ft_append3(mut c, level+1, a.mid, bridge_nodes, u8(group_count), b.mid)
	mut pre := [4]i32{}; for i in 0 .. int(a.plen) { pre[i] = a.refs[i] }
	mut suf := [4]i32{}; for i in 0 .. int(b.slen) { suf[i] = b.refs[4+i] }
	return ft_deep(mut c, level, pre, a.plen, middle, suf, b.slen)
}

fn ft_predicate(mode int, target i64, measure FtMeasure) bool {
	return if mode == 0 { measure.count > target } else { measure.sum >= target }
}

fn ft_split_tree(mut c &FtContext, id i32, acc FtMeasure, mode int, target i64) FtSplit {
	t := c.objects[int(id)]
	if t.kind == 0 { return FtSplit{found: false, item: 0, left: 0, right: id} }
	if t.kind == 1 {
		measure := ft_add(acc, ft_ref_measure(c, t.refs[0]))
		if ft_predicate(mode, target, measure) {
			return FtSplit{found: true, item: t.refs[0], left: ft_empty(mut c, t.level), right: ft_empty(mut c, t.level)}
		}
		return FtSplit{found: false, item: 0, left: id, right: ft_empty(mut c, t.level)}
	}
	mut prefix_items := [4]i32{}
	mut prefix_count := 0
	mut current := acc
	for i in 0 .. int(t.plen) {
		current = ft_add(current, ft_ref_measure(c, t.refs[i]))
		prefix_items[prefix_count] = t.refs[i]
		prefix_count++
		if ft_predicate(mode, target, current) {
			mut before := [16]i32{}; for j in 0 .. prefix_count-1 { before[j] = prefix_items[j] }
			mut rest_pre := [4]i32{}; for j in i+1 .. int(t.plen) { rest_pre[j-i-1] = t.refs[j] }
			mut suffix := [4]i32{}; for j in 0 .. int(t.slen) { suffix[j] = t.refs[4+j] }
			left := ft_from_items(mut c, t.level, before, u8(prefix_count-1))
			right := ft_deep_left(mut c, t.level, rest_pre, u8(int(t.plen)-i-1), t.mid, suffix, t.slen)
			return FtSplit{found: true, item: t.refs[i], left: left, right: right}
		}
	}
	mut after_prefix := acc
	for i in 0 .. int(t.plen) { after_prefix = ft_add(after_prefix, ft_ref_measure(c, t.refs[i])) }
	middle_measure := ft_tree_measure(c, t.mid)
	through_middle := ft_add(after_prefix, middle_measure)
	mut suffix := [4]i32{}; for i in 0 .. int(t.slen) { suffix[i] = t.refs[4+i] }
	if ft_predicate(mode, target, through_middle) {
	split_middle := ft_split_tree(mut c, t.mid, after_prefix, mode, target)
		if !split_middle.found { c.failed = true; return FtSplit{found: false, item: 0, left: id, right: ft_empty(mut c, t.level)} }
		node := c.objects[int(split_middle.item)]
		mut child_acc := ft_add(after_prefix, ft_tree_measure(c, split_middle.left))
		mut before := [4]i32{}; mut before_count := 0
		mut after := [4]i32{}; mut after_count := 0
		mut pivot := i32(0); mut found := false
		for i in 0 .. int(node.arity) {
			next := ft_add(child_acc, ft_ref_measure(c, node.refs[i]))
			if !found && ft_predicate(mode, target, next) { pivot = node.refs[i]; found = true }
			else if !found { before[before_count] = node.refs[i]; before_count++; child_acc = next }
			else { after[after_count] = node.refs[i]; after_count++ }
		}
		if !found { c.failed = true; return FtSplit{found: false, item: 0, left: id, right: ft_empty(mut c, t.level)} }
		mut pre := [4]i32{}; for i in 0 .. int(t.plen) { pre[i] = t.refs[i] }
		mut left_suffix := [4]i32{}; for i in 0 .. before_count { left_suffix[i] = before[i] }
		mut right_pre := [4]i32{}; for i in 0 .. after_count { right_pre[i] = after[i] }
		left := ft_deep_right(mut c, t.level, pre, t.plen, split_middle.left, left_suffix, u8(before_count))
		right := ft_deep_left(mut c, t.level, right_pre, u8(after_count), split_middle.right, suffix, t.slen)
		return FtSplit{found: true, item: pivot, left: left, right: right}
	}
	current = through_middle
	mut suffix_items := [4]i32{}
	mut suffix_count := 0
	for i in 0 .. int(t.slen) {
		current = ft_add(current, ft_ref_measure(c, t.refs[4+i]))
		suffix_items[suffix_count] = t.refs[4+i]
		suffix_count++
		if ft_predicate(mode, target, current) {
			mut left_suf := [4]i32{}; for j in 0 .. suffix_count-1 { left_suf[j] = suffix_items[j] }
			mut pre := [4]i32{}; for j in 0 .. int(t.plen) { pre[j] = t.refs[j] }
			left := ft_deep_right(mut c, t.level, pre, t.plen, t.mid, left_suf, u8(suffix_count-1))
			mut after_items := [16]i32{}; for j in suffix_count .. int(t.slen) { after_items[j-suffix_count] = t.refs[4+j] }
			right := ft_from_items(mut c, t.level, after_items, u8(int(t.slen)-suffix_count))
			return FtSplit{found: true, item: t.refs[4+i], left: left, right: right}
		}
	}
	return FtSplit{found: false, item: 0, left: id, right: ft_empty(mut c, t.level)}
}

fn ft_item_value(item i32) i64 {
	return -i64(item) - 1
}

fn ft_store_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for i in 0 .. 8 { output[offset+i] = u8((bits >> (8*i)) & 255) }
}

@[export: 'measured_finger_tree_sequence']
pub fn measured_finger_tree_sequence(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > ft_max_parseable { return -1 }
		n0 := input[0]
		if n0 < 0 || n0 > 32 { return -1 }
		n := int(n0)
		if length < usize(n + 2) { return -1 }
		q_value := input[n+1]
		if q_value < 1 || q_value > ft_max_q { return -1 }
		q := int(q_value)
		if length != usize(n + 2 + 5*q) || length > ft_max_input { return -1 }

		mut ctx := FtContext{}
		mut tree := ft_empty(mut ctx, 0)
		for i in 0 .. n {
			value := input[1+i]
			if value < 0 || value > ft_max_value { return -1 }
			tree = ft_snoc(mut ctx, 0, tree, i32(-value - 1))
		}
		if ctx.failed { return -1 }
		initial_measure := ft_tree_measure(ctx, tree)
		if initial_measure.count > ft_max_length || initial_measure.sum > ft_max_sum { return -1 }
		mut roots := [ft_max_roots]FtRoot{}
		roots[0] = FtRoot{tree: tree, length: initial_measure.count, sum: initial_measure.sum}
		mut root_count := 1
		mut cursor := n + 2
		mut records := [ft_max_q * 7]i64{}
		for op in 0 .. q {
			tag := input[cursor]
			aa := input[cursor+1]
			bb := input[cursor+2]
			x := input[cursor+3]
			y := input[cursor+4]
			cursor += 5
			if tag < 0 || tag > 6 || aa < 0 || aa >= root_count || root_count >= ft_max_roots { return -1 }
			a := int(aa)
			first := roots[a].tree
			mut result := i32(0)
			mut result_right := i32(0)
			mut right_root := i32(-1)
			mut right_length := i64(-1)
			mut right_sum := i64(-1)
			mut auxiliary := i64(-1)
			mut two_results := false
			if tag == 0 || tag == 1 {
				if bb != -1 || y != -1 || x < 0 || x > ft_max_value || roots[a].length >= ft_max_length || roots[a].sum + x > ft_max_sum { return -1 }
				item := i32(-x - 1)
				result = if tag == 0 { ft_cons(mut ctx, 0, item, first) } else { ft_snoc(mut ctx, 0, first, item) }
			} else if tag == 2 || tag == 3 {
				if bb != -1 || x != -1 || y != -1 || roots[a].length == 0 { return -1 }
				view := if tag == 2 { ft_view_left(mut ctx, 0, first) } else { ft_view_right(mut ctx, 0, first) }
				if !view.found { return -1 }
				result = view.tree
				auxiliary = ft_item_value(view.item)
			} else if tag == 4 {
				if bb < 0 || bb >= root_count || x != -1 || y != -1 { return -1 }
				b := int(bb)
				if roots[a].length + roots[b].length > ft_max_length || roots[a].sum + roots[b].sum > ft_max_sum { return -1 }
				bridge := [16]i32{}
				result = ft_append3(mut ctx, 0, first, bridge, 0, roots[b].tree)
			} else {
				if bb != -1 || y != -1 || (tag == 5 && (x < 0 || x > roots[a].length)) || (tag == 6 && (x < 1 || x > ft_max_sum)) { return -1 }
				mode := if tag == 5 { 0 } else { 1 }
				split := ft_split_tree(mut ctx, first, FtMeasure{}, mode, x)
				if split.found {
					if tag == 5 {
						result = split.left
						result_right = ft_cons(mut ctx, 0, split.item, split.right)
						auxiliary = x
					} else {
						result = ft_snoc(mut ctx, 0, split.left, split.item)
						result_right = split.right
						auxiliary = i64(ft_tree_measure(ctx, result).count)
					}
				} else {
					result = first
					result_right = ft_empty(mut ctx, 0)
					auxiliary = if tag == 5 { x } else { -1 }
				}
				two_results = true
			}
			if ctx.failed { return -1 }
			left_measure := ft_tree_measure(ctx, result)
			if left_measure.count > ft_max_length || left_measure.sum > ft_max_sum { return -1 }
			left_root := i32(root_count)
			roots[root_count] = FtRoot{tree: result, length: left_measure.count, sum: left_measure.sum}
			root_count++
			if two_results {
				right_measure := ft_tree_measure(ctx, result_right)
				if right_measure.count > ft_max_length || right_measure.sum > ft_max_sum || root_count >= ft_max_roots { return -1 }
				right_root = i32(root_count)
				right_length = i64(right_measure.count)
				right_sum = right_measure.sum
				roots[root_count] = FtRoot{tree: result_right, length: right_measure.count, sum: right_measure.sum}
				root_count++
			}
			offset := 7 * op
			records[offset] = i64(left_root)
			records[offset+1] = i64(left_measure.count)
			records[offset+2] = left_measure.sum
			records[offset+3] = i64(right_root)
			records[offset+4] = right_length
			records[offset+5] = right_sum
			records[offset+6] = auxiliary
		}
		bytes := 56 * q
		if output == nil || capacity < usize(bytes) { return -2 }
		mut staged := [1792]u8{}
		for i in 0 .. 7*q { ft_store_i64(mut &staged[0], 8*i, records[i]) }
		for i in 0 .. bytes { output[i] = staged[i] }
		return i64(bytes)
	}
}
