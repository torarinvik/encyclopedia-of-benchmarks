package main

import "core:c"

MAX_WORDS :: 16
MAX_QUERIES :: 8
MAX_WORD_LENGTH :: 10

valid_word :: proc(word: i64) -> bool {
	if word < 0 || (u64(word) >> 44) != 0 do return false
	packed := u64(word)
	word_length := int((packed >> 40) & 15)
	if word_length > MAX_WORD_LENGTH do return false
	for position in 0..<MAX_WORD_LENGTH {
		symbol := int((packed >> u64(4 * position)) & 15)
		if position < word_length {
			if symbol == 0 do return false
		} else if symbol != 0 do return false
	}
	return true
}

edit_distance :: proc(left, right: i64) -> int {
	a := u64(left)
	b := u64(right)
	n := int((a >> 40) & 15)
	m := int((b >> 40) & 15)
	previous: [11]int = {}
	current: [11]int = {}
	for j in 0..=m do previous[j] = j
	for i in 1..=n {
		current[0] = i
		a_symbol := (a >> u64(4 * (i - 1))) & 15
		for j in 1..=m {
			b_symbol := (b >> u64(4 * (j - 1))) & 15
			replacement := previous[j - 1] + int(a_symbol != b_symbol)
			current[j] = min(previous[j] + 1, current[j - 1] + 1, replacement)
		}
		previous = current
	}
	return previous[m]
}

@(export)
bk_tree_edit_distance_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 28 do return -1
	n_value := input[0]
	q_value := input[1]
	radius_value := input[2]
	if n_value < 0 || n_value > MAX_WORDS || q_value < 0 || q_value > MAX_QUERIES ||
		radius_value < 0 || radius_value > 3 || length != c.size_t(3 + n_value + q_value) do return -1
	n := int(n_value)
	q := int(q_value)
	radius := int(radius_value)
	for i in 0..<n+q {
		if !valid_word(input[i + 3]) do return -1
	}
	for i in 0..<n {
		for j in 0..<i {
			if input[i + 3] == input[j + 3] do return -1
		}
	}

	children: [176]int = {}
	for i in 0..<176 do children[i] = -1
	for node in 1..<n {
		pivot := 0
		for {
			edge := edit_distance(input[node + 3], input[pivot + 3])
			slot := pivot * 11 + edge
			if children[slot] == -1 {
				children[slot] = node
				break
			}
			pivot = children[slot]
		}
	}

	result := i64(0)
	for query_index in 0..<q {
		matches := i64(0)
		index_sum := i64(0)
		if n != 0 {
			stack: [16]int = {}
			top := 1
			stack[0] = 0
			for top != 0 {
				top -= 1
				node := stack[top]
				distance := edit_distance(input[3 + n + query_index], input[node + 3])
				if distance <= radius {
					matches += 1
					index_sum += i64(node)
				}
				low := max(0, distance - radius)
				high := min(MAX_WORD_LENGTH, distance + radius)
				for edge in low..=high {
					child := children[node * 11 + edge]
					if child >= 0 {
						stack[top] = child
						top += 1
					}
				}
			}
		}
		result += i64(query_index + 1) * (17 * matches + index_sum)
	}
	return result
}
