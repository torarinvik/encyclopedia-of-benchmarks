module mo_with_modifications

import 'core:c'

const max_n = 64
const max_q = 64

struct Query {
	left int
	right int
	time int
	ordinal int
}

struct Change {
	position int
	before_value int
	after_value int
}

struct Window {
mut:
	values [max_n]int
	frequencies [16]int
	distinct_count int
	left int
	right int
}

fn add_value(mut window Window, position int) {
	value := window.values[position]
	if window.frequencies[value] == 0 { window.distinct_count++ }
	window.frequencies[value]++
}

fn remove_value(mut window Window, position int) {
	value := window.values[position]
	window.frequencies[value]--
	if window.frequencies[value] == 0 { window.distinct_count-- }
}

fn replace_value(mut window Window, position int, new_value int) {
	active := position >= window.left && position <= window.right
	if active { remove_value(mut window, position) }
	window.values[position] = new_value
	if active { add_value(mut window, position) }
}

fn query_before(a Query, b Query, block_size int) bool {
	left_block_a := a.left / block_size
	left_block_b := b.left / block_size
	if left_block_a != left_block_b { return left_block_a < left_block_b }
	right_block_a := a.right / block_size
	right_block_b := b.right / block_size
	if right_block_a != right_block_b { return right_block_a < right_block_b }
	if a.time != b.time { return a.time < b.time }
	return a.ordinal < b.ordinal
}

@[export: 'mo_with_modifications']
pub fn mo_with_modifications(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 258 { return -1 }
		n64, q64 := input[0], input[1]
		if n64 < 1 || n64 > i64(max_n) || q64 < 0 || q64 > i64(max_q) || int(length) != 2 + int(n64) + 3 * int(q64) { return -1 }
		n, q := int(n64), int(q64)
		mut initial := [max_n]int{}
		for i in 0 .. n {
			value := input[2 + i]
			if value < 0 || value > 15 { return -1 }
			initial[i] = int(value)
		}
		operation_offset := 2 + n
		for i in 0 .. q {
			op := input[operation_offset + 3 * i]
			first := input[operation_offset + 3 * i + 1]
			second := input[operation_offset + 3 * i + 2]
			if op == 0 {
				if first < 0 || first >= n64 || second < 0 || second > 15 { return -1 }
			} else if op == 1 {
				if first < 0 || second < first || second >= n64 { return -1 }
			} else { return -1 }
		}

		parse_state := initial
		mut changes := [max_q]Change{}
		mut queries := [max_q]Query{}
		mut change_count, query_count := 0, 0
		for i in 0 .. q {
			op := input[operation_offset + 3 * i]
			first := int(input[operation_offset + 3 * i + 1])
			second := int(input[operation_offset + 3 * i + 2])
			if op == 0 {
				changes[change_count] = Change{first, parse_state[first], second}
				parse_state[first] = second
				change_count++
			} else {
				queries[query_count] = Query{first, second, change_count, query_count}
				query_count++
			}
		}

		mut block_size := 1
		for (block_size + 1) * (block_size + 1) * (block_size + 1) <= n * n { block_size++ }
		for i in 1 .. query_count {
			current := queries[i]
			mut position := i
			for position > 0 && query_before(current, queries[position - 1], block_size) {
				queries[position] = queries[position - 1]
				position--
			}
			queries[position] = current
		}

		mut window := Window{}
		window.values = initial
		window.left = 0
		window.right = -1
		mut current_time := 0
		mut answers := [max_q]int{}
		for sorted in 0 .. query_count {
			query := queries[sorted]
			for current_time < query.time {
				change := changes[current_time]
				replace_value(mut window, change.position, change.after_value)
				current_time++
			}
			for current_time > query.time {
				current_time--
				change := changes[current_time]
				replace_value(mut window, change.position, change.before_value)
			}
			for window.left > query.left { window.left--; add_value(mut window, window.left) }
			for window.right < query.right { window.right++; add_value(mut window, window.right) }
			for window.left < query.left { remove_value(mut window, window.left); window.left++ }
			for window.right > query.right { remove_value(mut window, window.right); window.right-- }
			answers[query.ordinal] = window.distinct_count
		}

		mut checksum := i64(0)
		for ordinal in 0 .. query_count { checksum += i64(ordinal + 1) * i64(answers[ordinal] + 1) }
		return checksum
	}
}
