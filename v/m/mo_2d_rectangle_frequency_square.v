module mo_2d_rectangle_frequency_square

const max_n = 8
const max_q = 32
const max_cells = 64
const max_input = 194
const max_parseable = 195

struct RectQuery {
	top int
	left int
	bottom int
	right int
	ordinal int
}

struct FrequencyState {
mut:
	counts [8]int
	square_sum i64
}

fn query_before(a RectQuery, b RectQuery, block_size int) bool {
	if a.top / block_size != b.top / block_size { return a.top / block_size < b.top / block_size }
	if a.left / block_size != b.left / block_size { return a.left / block_size < b.left / block_size }
	if a.bottom / block_size != b.bottom / block_size { return a.bottom / block_size < b.bottom / block_size }
	if a.right / block_size != b.right / block_size { return a.right / block_size < b.right / block_size }
	if a.top != b.top { return a.top < b.top }
	if a.left != b.left { return a.left < b.left }
	if a.bottom != b.bottom { return a.bottom < b.bottom }
	if a.right != b.right { return a.right < b.right }
	if a.ordinal != b.ordinal { return a.ordinal < b.ordinal }
	return false
}

fn (mut state FrequencyState) add(value int) {
	old := state.counts[value]
	state.square_sum += i64(2 * old + 1)
	state.counts[value] = old + 1
}

fn (mut state FrequencyState) remove(value int) {
	old := state.counts[value]
	state.square_sum += i64(1 - 2 * old)
	state.counts[value] = old - 1
}

@[export: 'mo_2d_rectangle_frequency_square']
pub fn mo_2d_rectangle_frequency_square(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_parseable) { return -1 }
		n_value, q_value := input[0], input[1]
		if n_value < 1 || n_value > max_n || q_value < 0 || q_value > max_q { return -1 }
		n, q := int(n_value), int(q_value)
		if int(length) != 2 + n * n + 4 * q || length > usize(max_input) { return -1 }

		mut matrix := [max_cells]int{}
		for cell in 0 .. n * n {
			value := input[2 + cell]
			if value < 0 || value > 7 { return -1 }
			matrix[cell] = int(value)
		}

		mut queries := [max_q]RectQuery{}
		mut cursor := 2 + n * n
		for query_index in 0 .. q {
			top_value, left_value := input[cursor], input[cursor + 1]
			bottom_value, right_value := input[cursor + 2], input[cursor + 3]
			if top_value < 0 || top_value >= n_value || bottom_value < top_value || bottom_value >= n_value { return -1 }
			if left_value < 0 || left_value >= n_value || right_value < left_value || right_value >= n_value { return -1 }
			queries[query_index] = RectQuery{int(top_value), int(left_value), int(bottom_value), int(right_value), query_index}
			cursor += 4
		}
		if q == 0 { return 0 }

		mut block_size := 1
		n_fourth := n * n * n * n
		for block_size < n {
			candidate := block_size + 1
			if q * candidate * candidate * candidate * candidate <= n_fourth { block_size = candidate } else { break }
		}
		for index in 1 .. q {
			item := queries[index]
			mut position := index
			for position > 0 && query_before(item, queries[position - 1], block_size) {
				queries[position] = queries[position - 1]
				position--
			}
			queries[position] = item
		}

		mut answers := [max_q]i64{}
		mut state := FrequencyState{}
		first := queries[0]
		mut current_top, current_bottom := first.top, first.bottom
		mut current_left, current_right := first.left, first.right
		for row in current_top .. current_bottom + 1 {
			for column in current_left .. current_right + 1 { state.add(matrix[row * n + column]) }
		}
		answers[first.ordinal] = state.square_sum

		for sorted_position in 1 .. q {
			query := queries[sorted_position]
			for current_top > query.top {
				current_top--
				for column in current_left .. current_right + 1 { state.add(matrix[current_top * n + column]) }
			}
			for current_bottom < query.bottom {
				current_bottom++
				for column in current_left .. current_right + 1 { state.add(matrix[current_bottom * n + column]) }
			}
			for current_left > query.left {
				current_left--
				for row in current_top .. current_bottom + 1 { state.add(matrix[row * n + current_left]) }
			}
			for current_right < query.right {
				current_right++
				for row in current_top .. current_bottom + 1 { state.add(matrix[row * n + current_right]) }
			}
			for current_top < query.top {
				for column in current_left .. current_right + 1 { state.remove(matrix[current_top * n + column]) }
				current_top++
			}
			for current_bottom > query.bottom {
				for column in current_left .. current_right + 1 { state.remove(matrix[current_bottom * n + column]) }
				current_bottom--
			}
			for current_left < query.left {
				for row in current_top .. current_bottom + 1 { state.remove(matrix[row * n + current_left]) }
				current_left++
			}
			for current_right > query.right {
				for row in current_top .. current_bottom + 1 { state.remove(matrix[row * n + current_right]) }
				current_right--
			}
			answers[query.ordinal] = state.square_sum
		}

		mut checksum := i64(0)
		for index in 0 .. q { checksum += i64(index + 1) * answers[index] }
		return checksum
	}
}
