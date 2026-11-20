module main

const max_words = 16
const max_queries = 8
const max_word_length = 10

fn valid_word(word i64) bool {
	if word < 0 { return false }
	packed := u64(word)
	if packed >> 44 != 0 { return false }
	word_length := int((packed >> 40) & 15)
	if word_length > max_word_length { return false }
	for position in 0 .. max_word_length {
		symbol := int((packed >> u64(4 * position)) & 15)
		if position < word_length {
			if symbol == 0 { return false }
		} else if symbol != 0 { return false }
	}
	return true
}

fn edit_distance(left i64, right i64) int {
	a := u64(left)
	b := u64(right)
	n := int((a >> 40) & 15)
	m := int((b >> 40) & 15)
	mut previous := [max_word_length + 1]int{init: 0}
	mut current := [max_word_length + 1]int{init: 0}
	for j in 0 .. m + 1 { previous[j] = j }
	for i in 1 .. n + 1 {
		current[0] = i
		a_symbol := (a >> u64(4 * (i - 1))) & 15
		for j in 1 .. m + 1 {
			b_symbol := (b >> u64(4 * (j - 1))) & 15
			replacement := previous[j - 1] + if a_symbol == b_symbol { 0 } else { 1 }
			current[j] = min(previous[j] + 1, current[j - 1] + 1, replacement)
		}
		previous = current
	}
	return previous[m]
}

@[export: 'bk_tree_edit_distance_search']
pub fn bk_tree_edit_distance_search(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 28 { return -1 }
		n_value := input[0]
		q_value := input[1]
		radius_value := input[2]
		if n_value < 0 || n_value > max_words || q_value < 0 || q_value > max_queries ||
			radius_value < 0 || radius_value > 3 || length != usize(3 + n_value + q_value) { return -1 }
		n := int(n_value)
		q := int(q_value)
		radius := int(radius_value)
		for i in 0 .. n + q { if !valid_word(input[i + 3]) { return -1 } }
		for i in 0 .. n { for j in 0 .. i { if input[i + 3] == input[j + 3] { return -1 } } }

		mut children := [max_words * (max_word_length + 1)]i32{init: 0}
		for i in 0 .. children.len { children[i] = -1 }
		for node in 1 .. n {
			mut pivot := 0
			for {
				edge := edit_distance(input[node + 3], input[pivot + 3])
				slot := pivot * (max_word_length + 1) + edge
				if children[slot] == -1 { children[slot] = i32(node); break }
				pivot = int(children[slot])
			}
		}

		mut result := i64(0)
		for query_index in 0 .. q {
			mut matches := i64(0)
			mut index_sum := i64(0)
			if n != 0 {
				mut stack := [max_words]int{init: 0}
				mut top := 1
				for top != 0 {
					top--
					node := stack[top]
					distance := edit_distance(input[3 + n + query_index], input[node + 3])
					if distance <= radius { matches++; index_sum += i64(node) }
					low := max(0, distance - radius)
					high := min(max_word_length, distance + radius)
					for edge in low .. high + 1 {
						child := children[node * (max_word_length + 1) + edge]
						if child >= 0 { stack[top] = int(child); top++ }
					}
				}
			}
			result += i64(query_index + 1) * (17 * matches + index_sum)
		}
		return result
	}
}
