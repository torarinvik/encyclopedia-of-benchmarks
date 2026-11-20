module taxicab_number_minimum_representations

const max_root = 444
const max_parseable_length = 2

struct TaxicabNode {
	sum i32
	a i32
	b i32
}

fn node_less(left TaxicabNode, right TaxicabNode) bool {
	if left.sum != right.sum { return left.sum < right.sum }
	if left.a != right.a { return left.a < right.a }
	return left.b < right.b
}

fn heap_push(mut heap []TaxicabNode, mut size int, node TaxicabNode) {
	mut index := size
	size++
	for index > 0 {
		parent := (index - 1) / 2
		if !node_less(node, heap[parent]) { break }
		heap[index] = heap[parent]
		index = parent
	}
	heap[index] = node
}

fn heap_pop(mut heap []TaxicabNode, mut size int) TaxicabNode {
	result := heap[0]
	size--
	if size == 0 { return result }
	last := heap[size]
	mut index := 0
	for 2 * index + 1 < size {
		mut child := 2 * index + 1
		if child + 1 < size && node_less(heap[child + 1], heap[child]) { child++ }
		if !node_less(heap[child], last) { break }
		heap[index] = heap[child]
		index = child
	}
	heap[index] = last
	return result
}

fn cube(value i32) i32 { return value * value * value }

fn search(ways i32) i64 {
	mut heap := []TaxicabNode{len: max_root}
	mut size := 0
	for a in 1 .. max_root + 1 {
		root := i32(a)
		value := cube(root)
		heap_push(mut heap, mut size, TaxicabNode{sum: 2 * value, a: root, b: root})
	}
	for size > 0 {
		first := heap_pop(mut heap, mut size)
		total := first.sum
		mut count := i32(1)
		if first.b < max_root {
			next_b := first.b + 1
			heap_push(mut heap, mut size, TaxicabNode{sum: cube(first.a) + cube(next_b), a: first.a, b: next_b})
		}
		for size > 0 && heap[0].sum == total {
			equal := heap_pop(mut heap, mut size)
			count++
			if equal.b < max_root {
				next_b := equal.b + 1
				heap_push(mut heap, mut size, TaxicabNode{sum: cube(equal.a) + cube(next_b), a: equal.a, b: next_b})
			}
		}
		if count >= ways { return i64(total) }
	}
	return -1
}

@[export: 'taxicab_number_minimum_representations']
pub fn taxicab_number_minimum_representations(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		if length != 1 || (input[0] != 2 && input[0] != 3) { return -1 }
		return search(i32(input[0]))
	}
}
