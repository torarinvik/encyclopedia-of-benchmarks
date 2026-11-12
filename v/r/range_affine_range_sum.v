module range_affine_range_sum

const modulus = i64(998244353)
const max_length = 64
const max_operations = 64
const tree_nodes = 256
const max_parseable_input_length = 387

struct AffineTree {
	mut:
		sum [tree_nodes]i64
		lazy_mul [tree_nodes]i64
		lazy_add [tree_nodes]i64
}

fn apply(mut tree AffineTree, node int, length int, a i64, b i64) {
	tree.sum[node] = (a * tree.sum[node] + b * i64(length)) % modulus
	tree.lazy_mul[node] = (a * tree.lazy_mul[node]) % modulus
	tree.lazy_add[node] = (a * tree.lazy_add[node] + b) % modulus
}

fn push(mut tree AffineTree, node int, low int, high int) {
	if high - low <= 1 || (tree.lazy_mul[node] == 1 && tree.lazy_add[node] == 0) { return }
	middle := low + (high-low)/2
	a, b := tree.lazy_mul[node], tree.lazy_add[node]
	apply(mut tree, node*2, middle-low, a, b)
	apply(mut tree, node*2+1, high-middle, a, b)
	tree.lazy_mul[node] = 1
	tree.lazy_add[node] = 0
}

fn build(mut tree AffineTree, values &i64, node int, low int, high int) {
	if high - low == 1 {
		tree.sum[node] = unsafe { values[low] }
		return
	}
	middle := low + (high-low)/2
	build(mut tree, values, node*2, low, middle)
	build(mut tree, values, node*2+1, middle, high)
	tree.sum[node] = (tree.sum[node*2] + tree.sum[node*2+1]) % modulus
}

fn update(mut tree AffineTree, ql int, qr int, node int, low int, high int, a i64, b i64) {
	if ql <= low && high <= qr { apply(mut tree, node, high-low, a, b); return }
	if qr <= low || high <= ql { return }
	push(mut tree, node, low, high)
	middle := low + (high-low)/2
	update(mut tree, ql, qr, node*2, low, middle, a, b)
	update(mut tree, ql, qr, node*2+1, middle, high, a, b)
	tree.sum[node] = (tree.sum[node*2] + tree.sum[node*2+1]) % modulus
}

fn query(mut tree AffineTree, ql int, qr int, node int, low int, high int) i64 {
	if ql <= low && high <= qr { return tree.sum[node] }
	if qr <= low || high <= ql { return 0 }
	push(mut tree, node, low, high)
	middle := low + (high-low)/2
	return (query(mut tree, ql, qr, node*2, low, middle) + query(mut tree, ql, qr, node*2+1, middle, high)) % modulus
}

@[export: 'range_affine_range_sum_benchmark']
pub fn range_affine_range_sum_benchmark(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_parseable_input_length { return -1 }
		if input[0] < 1 || input[0] > max_length { return -1 }
		n := int(input[0])
		if length < usize(n+2) { return -1 }
		mut initial := [max_length]i64{}
		for i in 0 .. n {
			if input[i+1] < 0 || input[i+1] >= modulus { return -1 }
			initial[i] = input[i+1]
		}
		if input[n+1] < 1 || input[n+1] > max_operations { return -1 }
		operation_count := int(input[n+1])
		mut tree := AffineTree{}
		for i in 0 .. tree_nodes { tree.lazy_mul[i] = 1 }
		build(mut tree, &initial[0], 1, 0, n)
		mut cursor := n+2
		mut checksum := i64(0)
		for operation in 0 .. operation_count {
			if cursor >= int(length) { return -1 }
			opcode := input[cursor]
			cursor++
			if opcode == 0 {
				if cursor+4 > int(length) { return -1 }
				left, right, a, b := input[cursor], input[cursor+1], input[cursor+2], input[cursor+3]
				cursor += 4
				if left < 0 || left >= right || right > i64(n) || a < 1 || a >= modulus || b < 0 || b >= modulus { return -1 }
				update(mut tree, int(left), int(right), 1, 0, n, a, b)
			} else if opcode == 1 {
				if cursor+2 > int(length) { return -1 }
				left, right := input[cursor], input[cursor+1]
				cursor += 2
				if left < 0 || left >= right || right > i64(n) { return -1 }
				result := query(mut tree, int(left), int(right), 1, 0, n)
				checksum += i64(operation+1) * (result + modulus)
			} else { return -1 }
		}
		if cursor == int(length) { return checksum }
		return -1
	}
}
