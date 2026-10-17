module minimax

fn evaluate(values &i64, index int, depth int, height int, maximizing bool) i64 {
	if depth == height { return unsafe { values[2 + index] } }
	left := evaluate(values, index * 2, depth + 1, height, !maximizing)
	right := evaluate(values, index * 2 + 1, depth + 1, height, !maximizing)
	if maximizing { return if left > right { left } else { right } }
	return if left < right { left } else { right }
}

@[export: 'minimax']
pub fn minimax(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > 34 { return -2147483649 }
	leaf_count := unsafe { values[0] }
	first_turn_is_max := unsafe { values[1] }
	if leaf_count < 1 || leaf_count > 32 || (leaf_count & (leaf_count - 1)) != 0 { return -2147483649 }
	if (first_turn_is_max != 0 && first_turn_is_max != 1) || length != usize(2 + leaf_count) { return -2147483649 }
	unsafe {
		for leaf in 0 ..< int(leaf_count) {
			if values[2 + leaf] < -2147483648 || values[2 + leaf] > 2147483647 { return -2147483649 }
		}
	}
	mut height := 0
	mut width := int(leaf_count)
	for width > 1 { width /= 2; height++ }
	return evaluate(values, 0, 0, height, first_turn_is_max == 1)
}
