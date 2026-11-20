package measured_finger_tree_sequence

import "core:c"

Q_MAX :: 32
ROOT_MAX :: 65
ARENA_MAX :: 16384
POOL_MAX :: 8192
LEVEL_MAX :: 16
INITIAL_MAX :: 32
LENGTH_MAX :: 64
VALUE_MAX :: i64(1_000_000)
SUM_MAX :: i64(64_000_000)
INPUT_MAX :: 195
OUTPUT_MAX :: 1792

Measure :: struct { count: i32, sum: i64 }
Tree :: struct {
	kind: u8,
	level: u8,
	prefix_len: u8,
	suffix_len: u8,
	middle: i32,
	prefix: [4]i32,
	suffix: [4]i32,
	count: i32,
	sum: i64,
}
Node :: struct { arity: u8, children: [3]i32, count: i32, sum: i64 }
Root :: struct { tree: i32, length: i32, sum: i64 }
View :: struct { found: bool, item: i32, tree: i32 }
Split :: struct { found: bool, item: i32, left: i32, right: i32 }
Context :: struct {
	trees: [POOL_MAX]Tree,
	nodes: [POOL_MAX]Node,
	tree_count: int,
	node_count: int,
	empty_tree: [LEVEL_MAX]i32,
	empty_ready: [LEVEL_MAX]bool,
	failed: bool,
}

ft_add_measure :: proc "contextless" (a, b: Measure) -> Measure {
	return Measure{a.count + b.count, a.sum + b.sum}
}

ft_ref_measure :: proc "contextless" (ctx: ^Context, item: i32) -> Measure {
	if item < 0 do return Measure{1, -i64(item) - 1}
	node := ctx.nodes[item]
	return Measure{node.count, node.sum}
}

ft_tree_measure :: proc "contextless" (ctx: ^Context, tree_id: i32) -> Measure {
	tree := ctx.trees[tree_id]
	return Measure{tree.count, tree.sum}
}

ft_alloc_tree :: proc "contextless" (ctx: ^Context) -> i32 {
	if ctx.tree_count + ctx.node_count >= ARENA_MAX || ctx.tree_count >= POOL_MAX {
		ctx.failed = true
		return 0
	}
	id := ctx.tree_count
	ctx.tree_count += 1
	ctx.trees[id] = Tree{}
	return i32(id)
}

ft_alloc_node :: proc "contextless" (ctx: ^Context) -> i32 {
	if ctx.tree_count + ctx.node_count >= ARENA_MAX || ctx.node_count >= POOL_MAX {
		ctx.failed = true
		return 0
	}
	id := ctx.node_count
	ctx.node_count += 1
	ctx.nodes[id] = Node{}
	return i32(id)
}

ft_empty :: proc "contextless" (ctx: ^Context, level: u8) -> i32 {
	if int(level) >= LEVEL_MAX {
		ctx.failed = true
		return 0
	}
	index := int(level)
	if ctx.empty_ready[index] do return ctx.empty_tree[index]
	id := ft_alloc_tree(ctx)
	ctx.trees[id].kind = 0
	ctx.trees[id].level = level
	ctx.trees[id].middle = -1
	ctx.empty_tree[index] = id
	ctx.empty_ready[index] = true
	return id
}

ft_single :: proc "contextless" (ctx: ^Context, level: u8, item: i32) -> i32 {
	id := ft_alloc_tree(ctx)
	measure := ft_ref_measure(ctx, item)
	ctx.trees[id] = Tree{
		kind = 1,
		level = level,
		prefix_len = 1,
		prefix = [4]i32{item, 0, 0, 0},
		count = measure.count,
		sum = measure.sum,
	}
	return id
}

ft_make_node :: proc "contextless" (ctx: ^Context, items: [^]i32, arity: u8) -> i32 {
	if arity < 2 || arity > 3 {
		ctx.failed = true
		return 0
	}
	id := ft_alloc_node(ctx)
	measure := Measure{}
	ctx.nodes[id].arity = arity
	for i := 0; i < int(arity); i += 1 {
		ctx.nodes[id].children[i] = items[i]
		measure = ft_add_measure(measure, ft_ref_measure(ctx, items[i]))
	}
	ctx.nodes[id].count = measure.count
	ctx.nodes[id].sum = measure.sum
	return id
}

ft_deep :: proc "contextless" (ctx: ^Context, level: u8, prefix: [^]i32, prefix_len: u8,
		middle: i32, suffix: [^]i32, suffix_len: u8) -> i32 {
	if prefix_len == 0 || suffix_len == 0 || prefix_len > 4 || suffix_len > 4 {
		ctx.failed = true
		return ft_empty(ctx, level)
	}
	id := ft_alloc_tree(ctx)
	ctx.trees[id].kind = 2
	ctx.trees[id].level = level
	ctx.trees[id].prefix_len = prefix_len
	ctx.trees[id].suffix_len = suffix_len
	ctx.trees[id].middle = middle
	measure := ft_tree_measure(ctx, middle)
	for i := 0; i < int(prefix_len); i += 1 {
		ctx.trees[id].prefix[i] = prefix[i]
		measure = ft_add_measure(measure, ft_ref_measure(ctx, prefix[i]))
	}
	for i := 0; i < int(suffix_len); i += 1 {
		ctx.trees[id].suffix[i] = suffix[i]
		measure = ft_add_measure(measure, ft_ref_measure(ctx, suffix[i]))
	}
	ctx.trees[id].count = measure.count
	ctx.trees[id].sum = measure.sum
	return id
}

ft_cons :: proc "contextless" (ctx: ^Context, level: u8, item: i32, tree_id: i32) -> i32 {
	tree := ctx.trees[tree_id]
	if tree.kind == 0 do return ft_single(ctx, level, item)
	if tree.kind == 1 {
		prefix := [1]i32{item}
		suffix := [1]i32{tree.prefix[0]}
		middle := ft_empty(ctx, level + 1)
		return ft_deep(ctx, level, &prefix[0], 1, middle, &suffix[0], 1)
	}
	if tree.prefix_len < 4 {
		var prefix: [4]i32
		prefix[0] = item
		for i := 0; i < int(tree.prefix_len); i += 1 { prefix[i+1] = tree.prefix[i] }
		return ft_deep(ctx, level, &prefix[0], tree.prefix_len+1, tree.middle,
			&tree.suffix[0], tree.suffix_len)
	}
	group := [3]i32{tree.prefix[1], tree.prefix[2], tree.prefix[3]}
	new_prefix := [2]i32{item, tree.prefix[0]}
	middle := ft_cons(ctx, level+1, ft_make_node(ctx, &group[0], 3), tree.middle)
	return ft_deep(ctx, level, &new_prefix[0], 2, middle, &tree.suffix[0], tree.suffix_len)
}

ft_snoc :: proc "contextless" (ctx: ^Context, level: u8, tree_id: i32, item: i32) -> i32 {
	tree := ctx.trees[tree_id]
	if tree.kind == 0 do return ft_single(ctx, level, item)
	if tree.kind == 1 {
		prefix := [1]i32{tree.prefix[0]}
		suffix := [1]i32{item}
		middle := ft_empty(ctx, level + 1)
		return ft_deep(ctx, level, &prefix[0], 1, middle, &suffix[0], 1)
	}
	if tree.suffix_len < 4 {
		suffix := tree.suffix
		suffix[tree.suffix_len] = item
		return ft_deep(ctx, level, &tree.prefix[0], tree.prefix_len, tree.middle,
			&suffix[0], tree.suffix_len+1)
	}
	group := [3]i32{tree.suffix[0], tree.suffix[1], tree.suffix[2]}
	new_suffix := [2]i32{tree.suffix[3], item}
	middle := ft_snoc(ctx, level+1, tree.middle, ft_make_node(ctx, &group[0], 3))
	return ft_deep(ctx, level, &tree.prefix[0], tree.prefix_len, middle,
		&new_suffix[0], 2)
}

ft_from_items :: proc "contextless" (ctx: ^Context, level: u8, items: [^]i32, count: u8) -> i32 {
	result := ft_empty(ctx, level)
	for i := 0; i < int(count); i += 1 {
		result = ft_snoc(ctx, level, result, items[i])
	}
	return result
}

ft_view_left :: proc "contextless" (ctx: ^Context, level: u8, tree_id: i32) -> View {
	tree := ctx.trees[tree_id]
	if tree.kind == 0 do return View{false, 0, tree_id}
	if tree.kind == 1 do return View{true, tree.prefix[0], ft_empty(ctx, level)}
	item := tree.prefix[0]
	var rest: i32
	if tree.prefix_len > 1 {
		rest = ft_deep(ctx, level, &tree.prefix[1], tree.prefix_len-1,
			tree.middle, &tree.suffix[0], tree.suffix_len)
	} else {
		view := ft_view_left(ctx, level+1, tree.middle)
		if !view.found {
			rest = ft_from_items(ctx, level, &tree.suffix[0], tree.suffix_len)
		} else {
			node := ctx.nodes[view.item]
			rest = ft_deep(ctx, level, &node.children[0], node.arity,
				view.tree, &tree.suffix[0], tree.suffix_len)
		}
	}
	return View{true, item, rest}
}

ft_view_right :: proc "contextless" (ctx: ^Context, level: u8, tree_id: i32) -> View {
	tree := ctx.trees[tree_id]
	if tree.kind == 0 do return View{false, 0, tree_id}
	if tree.kind == 1 do return View{true, tree.prefix[0], ft_empty(ctx, level)}
	item := tree.suffix[tree.suffix_len-1]
	var rest: i32
	if tree.suffix_len > 1 {
		rest = ft_deep(ctx, level, &tree.prefix[0], tree.prefix_len, tree.middle,
			&tree.suffix[0], tree.suffix_len-1)
	} else {
		view := ft_view_right(ctx, level+1, tree.middle)
		if !view.found {
			rest = ft_from_items(ctx, level, &tree.prefix[0], tree.prefix_len)
		} else {
			node := ctx.nodes[view.item]
			rest = ft_deep(ctx, level, &tree.prefix[0], tree.prefix_len,
				view.tree, &node.children[0], node.arity)
		}
	}
	return View{true, item, rest}
}

ft_deep_left :: proc "contextless" (ctx: ^Context, level: u8, prefix: [^]i32, prefix_len: u8,
		middle: i32, suffix: [^]i32, suffix_len: u8) -> i32 {
	if prefix_len > 0 do return ft_deep(ctx, level, prefix, prefix_len, middle, suffix, suffix_len)
	view := ft_view_left(ctx, level+1, middle)
	if !view.found do return ft_from_items(ctx, level, suffix, suffix_len)
	node := ctx.nodes[view.item]
	return ft_deep(ctx, level, &node.children[0], node.arity, view.tree, suffix, suffix_len)
}

ft_deep_right :: proc "contextless" (ctx: ^Context, level: u8, prefix: [^]i32, prefix_len: u8,
		middle: i32, suffix: [^]i32, suffix_len: u8) -> i32 {
	if suffix_len > 0 do return ft_deep(ctx, level, prefix, prefix_len, middle, suffix, suffix_len)
	view := ft_view_right(ctx, level+1, middle)
	if !view.found do return ft_from_items(ctx, level, prefix, prefix_len)
	node := ctx.nodes[view.item]
	return ft_deep(ctx, level, prefix, prefix_len, view.tree, &node.children[0], node.arity)
}

ft_group_nodes :: proc "contextless" (ctx: ^Context, items: [^]i32, count: u8, nodes: [^]i32) -> u8 {
	node_count: u8 = 0
	position: u8 = 0
	for position < count {
		remaining := count-position
		take: u8 = 3
		if remaining == 2 || remaining == 4 { take = 2 }
		if remaining == 1 {
			ctx.failed = true
			return node_count
		}
		nodes[node_count] = ft_make_node(ctx, &items[position], take)
		node_count += 1
		position += take
	}
	return node_count
}

ft_append3 :: proc "contextless" (ctx: ^Context, level: u8, left_id: i32,
		items: [^]i32, item_count: u8, right_id: i32) -> i32 {
	left := ctx.trees[left_id]
	right := ctx.trees[right_id]
	if left.kind == 0 {
		result := right_id
		for i := int(item_count)-1; i >= 0; i -= 1 { result = ft_cons(ctx, level, items[i], result) }
		return result
	}
	if right.kind == 0 {
		result := left_id
		for i := 0; i < int(item_count); i += 1 { result = ft_snoc(ctx, level, result, items[i]) }
		return result
	}
	if left.kind == 1 {
		result := right_id
		for i := int(item_count)-1; i >= 0; i -= 1 { result = ft_cons(ctx, level, items[i], result) }
		return ft_cons(ctx, level, left.prefix[0], result)
	}
	if right.kind == 1 {
		result := left_id
		for i := 0; i < int(item_count); i += 1 { result = ft_snoc(ctx, level, result, items[i]) }
		return ft_snoc(ctx, level, result, right.prefix[0])
	}
	var combined: [16]i32
	combined_count: u8 = 0
	for i := 0; i < int(left.suffix_len); i += 1 {
		combined[combined_count] = left.suffix[i]
		combined_count += 1
	}
	for i := 0; i < int(item_count); i += 1 {
		combined[combined_count] = items[i]
		combined_count += 1
	}
	for i := 0; i < int(right.prefix_len); i += 1 {
		combined[combined_count] = right.prefix[i]
		combined_count += 1
	}
	var middle_nodes: [8]i32
	middle_node_count := ft_group_nodes(ctx, &combined[0], combined_count, &middle_nodes)
	middle := ft_append3(ctx, level+1, left.middle, &middle_nodes[0], middle_node_count, right.middle)
	return ft_deep(ctx, level, &left.prefix[0], left.prefix_len, middle,
		&right.suffix[0], right.suffix_len)
}

ft_precedes_target :: proc "contextless" (mode: u8, target: i64, measure: Measure) -> bool {
	if mode == 0 do return i64(measure.count) > target
	return measure.sum >= target
}

// The returned pivot is excluded from both trees. The caller puts it on the
// contractually correct side: right for an index cut, left for a sum cut.
ft_split_tree :: proc "contextless" (ctx: ^Context, tree_id: i32, accumulated: Measure,
		mode: u8, target: i64) -> Split {
	tree := ctx.trees[tree_id]
	if tree.kind == 0 do return Split{false, 0, 0, tree_id}
	if tree.kind == 1 {
		if ft_precedes_target(mode, target,
			ft_add_measure(accumulated, ft_ref_measure(ctx, tree.prefix[0]))) {
			empty := ft_empty(ctx, tree.level)
			return Split{true, tree.prefix[0], empty, empty}
		}
		return Split{false, 0, tree_id, ft_empty(ctx, tree.level)}
	}

	current := accumulated
	for i := 0; i < int(tree.prefix_len); i += 1 {
		current = ft_add_measure(current, ft_ref_measure(ctx, tree.prefix[i]))
		if ft_precedes_target(mode, target, current) {
			left := ft_from_items(ctx, tree.level, &tree.prefix[0], u8(i))
			tail_count := tree.prefix_len-u8(i)-1
			tail := &tree.prefix[0]
			if tail_count > 0 { tail = &tree.prefix[i+1] }
			right := ft_deep_left(ctx, tree.level, tail, tail_count,
				tree.middle, &tree.suffix[0], tree.suffix_len)
			return Split{true, tree.prefix[i], left, right}
		}
	}

	before_middle := accumulated
	for i := 0; i < int(tree.prefix_len); i += 1 {
		before_middle = ft_add_measure(before_middle, ft_ref_measure(ctx, tree.prefix[i]))
	}
	middle_measure := ft_tree_measure(ctx, tree.middle)
	through_middle := ft_add_measure(before_middle, middle_measure)
	if ft_precedes_target(mode, target, through_middle) {
		middle_split := ft_split_tree(ctx, tree.middle, before_middle, mode, target)
		if !middle_split.found {
			ctx.failed = true
			return Split{false, 0, tree_id, ft_empty(ctx, tree.level)}
		}
		node := ctx.nodes[middle_split.item]
		before_child := ft_add_measure(before_middle, ft_tree_measure(ctx, middle_split.left))
		var preceding: [3]i32
		var following: [3]i32
		preceding_count: u8 = 0
		following_count: u8 = 0
		pivot: i32 = 0
		found := false
		for i := 0; i < int(node.arity); i += 1 {
			next := ft_add_measure(before_child, ft_ref_measure(ctx, node.children[i]))
			if !found && ft_precedes_target(mode, target, next) {
				pivot = node.children[i]
				found = true
			} else if !found {
				preceding[preceding_count] = node.children[i]
				preceding_count += 1
				before_child = next
			} else {
				following[following_count] = node.children[i]
				following_count += 1
			}
		}
		if !found {
			ctx.failed = true
			return Split{false, 0, tree_id, ft_empty(ctx, tree.level)}
		}
		left := ft_deep_right(ctx, tree.level, &tree.prefix[0], tree.prefix_len,
			middle_split.left, &preceding[0], preceding_count)
		right := ft_deep_left(ctx, tree.level, &following[0], following_count,
			middle_split.right, &tree.suffix[0], tree.suffix_len)
		return Split{true, pivot, left, right}
	}

	current = through_middle
	for i := 0; i < int(tree.suffix_len); i += 1 {
		current = ft_add_measure(current, ft_ref_measure(ctx, tree.suffix[i]))
		if ft_precedes_target(mode, target, current) {
			left := ft_deep_right(ctx, tree.level, &tree.prefix[0], tree.prefix_len,
				tree.middle, &tree.suffix[0], u8(i))
			tail_count := tree.suffix_len-u8(i)-1
			tail := &tree.suffix[0]
			if tail_count > 0 { tail = &tree.suffix[i+1] }
			right := ft_from_items(ctx, tree.level, tail, tail_count)
			return Split{true, tree.suffix[i], left, right}
		}
	}
	return Split{false, 0, tree_id, ft_empty(ctx, tree.level)}
}

ft_item_value :: proc "contextless" (item: i32) -> i64 { return -i64(item)-1 }

ft_put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> (8*byte)) }
}

@(export)
measured_finger_tree_sequence :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(INPUT_MAX) do return -1
	initial_count_word := input[0]
	if initial_count_word < 0 || initial_count_word > INITIAL_MAX do return -1
	initial_count := int(initial_count_word)
	if int(length) < initial_count+2 do return -1
	operation_count_word := input[initial_count+1]
	if operation_count_word < 1 || operation_count_word > Q_MAX do return -1
	operation_count := int(operation_count_word)
	if int(length) != initial_count+2+5*operation_count || length > c.size_t(194) do return -1

	var ctx: Context
	root_tree := ft_empty(&ctx, 0)
	for i := 0; i < initial_count; i += 1 {
		value := input[1+i]
		if value < 0 || value > VALUE_MAX do return -1
		root_tree = ft_snoc(&ctx, 0, root_tree, i32(-value-1))
	}
	if ctx.failed do return -1
	initial_measure := ft_tree_measure(&ctx, root_tree)
	if initial_measure.count > LENGTH_MAX || initial_measure.sum > SUM_MAX do return -1

	var roots: [ROOT_MAX]Root
	roots[0] = Root{root_tree, initial_measure.count, initial_measure.sum}
	root_count := 1
	input_at := initial_count+2
	var records: [Q_MAX*7]i64
	for operation := 0; operation < operation_count; operation += 1 {
		tag := input[input_at]
		first_word := input[input_at+1]
		second_word := input[input_at+2]
		argument := input[input_at+3]
		last_word := input[input_at+4]
		input_at += 5
		if tag < 0 || tag > 6 || first_word < 0 || first_word >= i64(root_count) || root_count >= ROOT_MAX do return -1
		first_root := int(first_word)
		source := roots[first_root].tree
		result_tree: i32 = 0
		second_tree: i32 = 0
		right_root: i32 = -1
		right_length: i32 = -1
		right_sum: i64 = -1
		auxiliary: i64 = -1
		has_second := false

		if tag <= 1 {
			if second_word != -1 || last_word != -1 || argument < 0 || argument > VALUE_MAX ||
				roots[first_root].length >= LENGTH_MAX || roots[first_root].sum+argument > SUM_MAX do return -1
			item := i32(-argument-1)
			if tag == 0 { result_tree = ft_cons(&ctx, 0, item, source) }
			else { result_tree = ft_snoc(&ctx, 0, source, item) }
		} else if tag <= 3 {
			if second_word != -1 || argument != -1 || last_word != -1 || roots[first_root].length == 0 do return -1
			view: View
			if tag == 2 { view = ft_view_left(&ctx, 0, source) }
			else { view = ft_view_right(&ctx, 0, source) }
			if !view.found do return -1
			result_tree = view.tree
			auxiliary = ft_item_value(view.item)
		} else if tag == 4 {
			if second_word < 0 || second_word >= i64(root_count) || argument != -1 || last_word != -1 do return -1
			second_root := int(second_word)
			if roots[first_root].length+roots[second_root].length > LENGTH_MAX ||
				roots[first_root].sum+roots[second_root].sum > SUM_MAX do return -1
			result_tree = ft_append3(&ctx, 0, source, nil, 0, roots[second_root].tree)
		} else {
			if second_word != -1 || last_word != -1 do return -1
			if tag == 5 && (argument < 0 || argument > i64(roots[first_root].length)) do return -1
			if tag == 6 && (argument < 1 || argument > SUM_MAX) do return -1
			mode: u8 = 1
			if tag == 5 { mode = 0 }
			split := ft_split_tree(&ctx, source, Measure{}, mode, argument)
			if split.found {
				has_second = true
				if tag == 5 {
					result_tree = split.left
					second_tree = ft_cons(&ctx, 0, split.item, split.right)
					auxiliary = argument
				} else {
					result_tree = ft_snoc(&ctx, 0, split.left, split.item)
					second_tree = split.right
					auxiliary = i64(ft_tree_measure(&ctx, result_tree).count)
				}
			} else {
				has_second = true
				result_tree = source
				second_tree = ft_empty(&ctx, 0)
				if tag == 5 { auxiliary = argument }
			}
		}

		if ctx.failed do return -1
		left_measure := ft_tree_measure(&ctx, result_tree)
		if left_measure.count > LENGTH_MAX || left_measure.sum > SUM_MAX do return -1
		left_root := i32(root_count)
		roots[root_count] = Root{result_tree, left_measure.count, left_measure.sum}
		root_count += 1
		if has_second {
			if root_count >= ROOT_MAX do return -1
			right_measure := ft_tree_measure(&ctx, second_tree)
			if right_measure.count > LENGTH_MAX || right_measure.sum > SUM_MAX do return -1
			right_root = i32(root_count)
			right_length = right_measure.count
			right_sum = right_measure.sum
			roots[root_count] = Root{second_tree, right_measure.count, right_measure.sum}
			root_count += 1
		}
		record_at := operation*7
		records[record_at] = i64(left_root)
		records[record_at+1] = i64(left_measure.count)
		records[record_at+2] = left_measure.sum
		records[record_at+3] = i64(right_root)
		records[record_at+4] = i64(right_length)
		records[record_at+5] = right_sum
		records[record_at+6] = auxiliary
	}

	bytes := 56*operation_count
	if output == nil || output_capacity < c.size_t(bytes) do return -2
	var staged: [OUTPUT_MAX]u8
	for i := 0; i < operation_count*7; i += 1 { ft_put_i64(&staged[0], i*8, records[i]) }
	for i := 0; i < bytes; i += 1 { output[i] = staged[i] }
	return i64(bytes)
}
