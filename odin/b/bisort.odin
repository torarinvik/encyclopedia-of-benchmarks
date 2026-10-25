MIN_SIZE :: 2
MAX_SIZE :: 1024
MAX_NODES :: MAX_SIZE - 1
MODULUS :: 10000
MULTIPLIER :: 31415821
VALUE_RANGE :: 100

Node :: struct {
	value: i32,
	left:  i32,
	right: i32,
}

multiply :: proc(p, q: i32) -> i32 {
	p_high := p / i32(MODULUS)
	p_low := p % i32(MODULUS)
	q_high := q / i32(MODULUS)
	q_low := q % i32(MODULUS)
	return ((p_low * q_high + p_high * q_low) % i32(MODULUS)) * i32(MODULUS) + p_low * q_low
}

next_random :: proc(seed: i32) -> i32 { return multiply(seed, i32(MULTIPLIER)) + 1 }

skip_random :: proc(seed_value, count: i32) -> i32 {
	seed := seed_value
	for _ in 0..<count { seed = next_random(seed) }
	return seed
}

make_tree :: proc(nodes: [^]Node, used: ^int, size, seed_value: i32) -> i32 {
	if size <= 1 do return -1
	seed := next_random(seed_value)
	index := i32(used^)
	used^ += 1
	nodes[index].value = seed % i32(VALUE_RANGE)
	half := size / 2
	nodes[index].left = make_tree(nodes, used, half, seed)
	nodes[index].right = make_tree(nodes, used, half, skip_random(seed, size + 1))
	return index
}

swap_left :: proc(nodes: [^]Node, left, right, left_left, right_left, left_value, right_value: i32) {
	nodes[right].value = left_value
	nodes[right].left = left_left
	nodes[left].left = right_left
	nodes[left].value = right_value
}

swap_right :: proc(nodes: [^]Node, left, right, left_right, right_right, left_value, right_value: i32) {
	nodes[right].value = left_value
	nodes[right].right = left_right
	nodes[left].right = right_right
	nodes[left].value = right_value
}

merge :: proc(nodes: [^]Node, root: i32, spill: i32, direction: i32) -> i32 {
	root_value := nodes[root].value
	left := nodes[root].left
	right := nodes[root].right
	right_exchange := (root_value > spill) != (direction != 0)
	if right_exchange {
		nodes[root].value = spill
		spill = root_value
	}
	for left >= 0 {
		left_value := nodes[left].value
		left_left := nodes[left].left
		left_right := nodes[left].right
		right_value := nodes[right].value
		right_left := nodes[right].left
		right_right := nodes[right].right
		element_exchange := (left_value > right_value) != (direction != 0)
		if right_exchange {
			if element_exchange {
				swap_right(nodes, left, right, left_right, right_right, left_value, right_value)
				left = left_left
				right = right_left
			} else {
				left = left_right
				right = right_right
			}
		} else if element_exchange {
			swap_left(nodes, left, right, left_left, right_left, left_value, right_value)
			left = left_right
			right = right_right
		} else {
			left = left_left
			right = right_left
		}
	}
	if nodes[root].left >= 0 {
		left_root := nodes[root].left
		right_root := nodes[root].right
		root_value = nodes[root].value
		nodes[root].value = merge(nodes, left_root, root_value, direction)
		spill = merge(nodes, right_root, spill, direction)
	}
	return spill
}

sort_tree :: proc(nodes: [^]Node, root: i32, spill: i32, direction: i32) -> i32 {
	if nodes[root].left < 0 {
		if (nodes[root].value > spill) != (direction != 0) {
			value := nodes[root].value
			nodes[root].value = spill
			return value
		}
		return spill
	}
	left := nodes[root].left
	right := nodes[root].right
	value := nodes[root].value
	nodes[root].value = sort_tree(nodes, left, value, direction)
	other_direction := i32(1)
	if direction != 0 { other_direction = 0 }
	spill = sort_tree(nodes, right, spill, other_direction)
	return merge(nodes, root, spill, direction)
}

checksum :: proc(nodes: [^]Node, index: i32, position, sum: ^i64) {
	if index < 0 do return
	checksum(nodes, nodes[index].left, position, sum)
	position^ += 1
	sum^ += position^ * i64(nodes[index].value)
	checksum(nodes, nodes[index].right, position, sum)
}

@(export)
bisort :: proc "c" (size: i64) -> i64 {
	if size < MIN_SIZE || size > MAX_SIZE do return -1
	var nodes: [MAX_NODES]Node
	used := 0
	root := make_tree(&nodes[0], &used, i32(size), 12345768)
	spill := next_random(245867) % i32(VALUE_RANGE)
	spill = sort_tree(&nodes[0], root, spill, 0)
	spill = sort_tree(&nodes[0], root, spill, 1)
	position: i64 = 0
	sum: i64 = 0
	checksum(&nodes[0], root, &position, &sum)
	position += 1
	return sum + position * i64(spill)
}
