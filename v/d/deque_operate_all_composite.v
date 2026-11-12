module deque_operate_all_composite

const max_operations = 64
const max_input_length = 1 + 3 * 64
const tree_base = 128
const tree_nodes = 256
const modulus = i64(998_244_353)

struct Affine { a i64; b i64 }

struct AggregateDeque {
mut:
	tree [tree_nodes]Affine
	head int
	tail int
}

fn identity() Affine {
	return Affine{a: 1, b: 0}
}

fn compose(first Affine, second Affine) Affine {
	return Affine{
		a: (second.a * first.a) % modulus
		b: (second.a * first.b + second.b) % modulus
	}
}

fn update(mut deque AggregateDeque, position int, value Affine) {
	mut node := tree_base + position
	deque.tree[node] = value
	for node > 1 {
		node /= 2
		deque.tree[node] = compose(deque.tree[node * 2], deque.tree[node * 2 + 1])
	}
}

@[export: 'deque_operate_all_composite']
pub fn deque_operate_all_composite(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 1 || length > max_input_length { return -1 }
	operation_value := unsafe { values[0] }
	if operation_value < 0 || operation_value > max_operations { return -1 }
	operation_count := int(operation_value)

	mut deque := AggregateDeque{head: 64, tail: 64}
	for mut node in 0 .. tree_nodes {
		deque.tree[node] = identity()
	}
	mut position := 1
	mut checksum := i64(0)
	mut query_number := i64(0)
	for _ in 0 .. operation_count {
		if position >= int(length) { return -1 }
		opcode := unsafe { values[position] }
		position++
		if opcode == 0 || opcode == 1 {
			if int(length) - position < 2 { return -1 }
			a := unsafe { values[position] }
			b := unsafe { values[position + 1] }
			position += 2
			if a < 1 || a >= modulus || b < 0 || b >= modulus { return -1 }
			function := Affine{a: a, b: b}
			if opcode == 0 {
				if deque.head == 0 { return -1 }
				deque.head--
				update(mut deque, deque.head, function)
			} else {
				if deque.tail == tree_base { return -1 }
				update(mut deque, deque.tail, function)
				deque.tail++
			}
		} else if opcode == 2 || opcode == 3 {
			if deque.head == deque.tail { return -1 }
			if opcode == 2 {
				update(mut deque, deque.head, identity())
				deque.head++
			} else {
				deque.tail--
				update(mut deque, deque.tail, identity())
			}
		} else if opcode == 4 {
			if position >= int(length) { return -1 }
			x := unsafe { values[position] }
			position++
			if x < 0 || x >= modulus { return -1 }
			answer := (deque.tree[1].a * x + deque.tree[1].b) % modulus
			query_number++
			checksum += query_number * (answer + 1)
		} else {
			return -1
		}
	}
	if position != int(length) { return -1 }
	return checksum
}
