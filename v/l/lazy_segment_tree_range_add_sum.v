module lazy_segment_tree_range_add_sum

const max_items = 256
const max_operations = 512
const max_input_length = 2306
const value_limit = i64(1_000_000)
const query_offset = i64(131_328_000_001)

fn lazy_apply(mut tree [512]i64, mut pending [512]i64, node int, segment_length int, delta i64) {
	tree[node] += delta * i64(segment_length)
	pending[node] += delta
}

fn lazy_push(mut tree [512]i64, mut pending [512]i64, node int, segment_length int) {
	if segment_length > 1 && pending[node] != 0 {
		child_length := segment_length / 2
		lazy_apply(mut tree, mut pending, 2 * node, child_length, pending[node])
		lazy_apply(mut tree, mut pending, 2 * node + 1, child_length, pending[node])
		pending[node] = 0
	}
}

fn lazy_add(mut tree [512]i64, mut pending [512]i64, node int, low int, high int,
	query_low int, query_high int, delta i64) {
	if query_low <= low && high <= query_high {
		lazy_apply(mut tree, mut pending, node, high - low, delta)
		return
	}
	lazy_push(mut tree, mut pending, node, high - low)
	middle := (low + high) / 2
	if query_low < middle {
		lazy_add(mut tree, mut pending, 2 * node, low, middle, query_low, query_high, delta)
	}
	if query_high > middle {
		lazy_add(mut tree, mut pending, 2 * node + 1, middle, high, query_low, query_high, delta)
	}
	tree[node] = tree[2 * node] + tree[2 * node + 1]
}

fn lazy_sum(mut tree [512]i64, mut pending [512]i64, node int, low int, high int,
	query_low int, query_high int) i64 {
	if query_low <= low && high <= query_high { return tree[node] }
	lazy_push(mut tree, mut pending, node, high - low)
	middle := (low + high) / 2
	mut result := i64(0)
	if query_low < middle {
		result += lazy_sum(mut tree, mut pending, 2 * node, low, middle, query_low, query_high)
	}
	if query_high > middle {
		result += lazy_sum(mut tree, mut pending, 2 * node + 1, middle, high, query_low, query_high)
	}
	return result
}

@[export: 'lazy_segment_tree_range_add_sum']
pub fn lazy_segment_tree_range_add_sum(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 3 || length > usize(max_input_length) { return -1 }
		item_count_value := values[0]
		if item_count_value < 1 || item_count_value > max_items { return -1 }
		item_count := int(item_count_value)
		if length < usize(item_count + 2) { return -1 }
		operation_count_value := values[item_count + 1]
		if operation_count_value < 0 || operation_count_value > max_operations { return -1 }
		operation_count := int(operation_count_value)
		if length != usize(item_count + 2 + 4 * operation_count) { return -1 }

		for index := 0; index < item_count; index++ {
			if values[index + 1] < -value_limit || values[index + 1] > value_limit { return -1 }
		}
		for operation := 0; operation < operation_count; operation++ {
			position := item_count + 2 + 4 * operation
			opcode, left, right, delta := values[position], values[position + 1], values[position + 2], values[position + 3]
			if left < 0 || left >= right || right > item_count_value { return -1 }
			if opcode == 0 {
				if delta < -value_limit || delta > value_limit { return -1 }
			} else if opcode == 1 {
				if delta != 0 { return -1 }
			} else { return -1 }
		}

		mut base := 1
		for base < item_count { base *= 2 }
		mut tree := [512]i64{}
		mut pending := [512]i64{}
		for index := 0; index < item_count; index++ { tree[base + index] = values[index + 1] }
		mut node := base
		for node > 1 {
			node--
			tree[node] = tree[2 * node] + tree[2 * node + 1]
		}

		mut checksum := i64(0)
		for operation := 0; operation < operation_count; operation++ {
			position := item_count + 2 + 4 * operation
			left := int(values[position + 1])
			right := int(values[position + 2])
			if values[position] == 0 {
				lazy_add(mut tree, mut pending, 1, 0, base, left, right, values[position + 3])
			} else {
				checksum += lazy_sum(mut tree, mut pending, 1, 0, base, left, right) + query_offset
			}
		}
		return checksum
	}
}
