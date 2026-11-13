package parallel_binary_search_range_threshold

import "core:c"

MAX_N :: 16
MAX_EVENTS :: 32
MAX_QUERIES :: 32
MAX_PARSEABLE_LENGTH :: 196

bit_add :: proc(bit: []i64, start: int, delta: i64, limit: int) {
	index := start
	for index <= limit + 1 {
		bit[index] += delta
		index += index & -index
	}
}

bit_sum :: proc(bit: []i64, start: int) -> i64 {
	index := start
	total: i64 = 0
	for index > 0 {
		total += bit[index]
		index -= index & -index
	}
	return total
}

range_add :: proc(bit1, bit2: []i64, n, left, right: int, delta: i64) {
	lo := left + 1
	hi := right + 1
	bit_add(bit1, lo, delta, n)
	bit_add(bit1, hi + 1, -delta, n)
	bit_add(bit2, lo, delta * i64(lo - 1), n)
	bit_add(bit2, hi + 1, -delta * i64(hi), n)
}

prefix_sum :: proc(bit1, bit2: []i64, count: int) -> i64 {
	return i64(count) * bit_sum(bit1, count) - bit_sum(bit2, count)
}

range_sum :: proc(bit1, bit2: []i64, left, right: int) -> i64 {
	return prefix_sum(bit1, bit2, right + 1) - prefix_sum(bit1, bit2, left)
}

@(export)
parallel_binary_search_range_threshold :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_PARSEABLE_LENGTH do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_EVENTS || input[2] < 0 || input[2] > MAX_QUERIES do return -1
	n := int(input[0])
	event_count := int(input[1])
	query_count := int(input[2])
	if int(length) != 3 + 3 * event_count + 3 * query_count do return -1

	var event_left: [MAX_EVENTS]int
	var event_right: [MAX_EVENTS]int
	var event_delta: [MAX_EVENTS]i64
	var query_left: [MAX_QUERIES]int
	var query_right: [MAX_QUERIES]int
	var query_target: [MAX_QUERIES]i64
	cursor := 3
	for event in 0..<event_count {
		left := input[cursor]
		right := input[cursor + 1]
		delta := input[cursor + 2]
		cursor += 3
		if left < 0 || left > right || right >= i64(n) || delta < 0 || delta > 1000 do return -1
		event_left[event] = int(left)
		event_right[event] = int(right)
		event_delta[event] = delta
	}
	for query in 0..<query_count {
		left := input[cursor]
		right := input[cursor + 1]
		target := input[cursor + 2]
		cursor += 3
		if left < 0 || left > right || right >= i64(n) || target < 1 || target > 512000 do return -1
		query_left[query] = int(left)
		query_right[query] = int(right)
		query_target[query] = target
	}

	var low: [MAX_QUERIES]i64
	var high: [MAX_QUERIES]i64
	var next_query: [MAX_QUERIES]i64
	for query in 0..<query_count {
		high[query] = i64(event_count + 1)
	}
	for {
		var heads: [MAX_EVENTS + 1]i64
		for time in 0..MAX_EVENTS + 1 {
			heads[time] = -1
		}
		for query in 0..<query_count {
			next_query[query] = -1
		}
		active := false
		for query in 0..<query_count {
			if high[query] - low[query] > 1 {
				active = true
				middle := int((low[query] + high[query]) / 2)
				next_query[query] = heads[middle]
				heads[middle] = i64(query)
			}
		}
		if !active do break

		var bit1: [MAX_N + 2]i64
		var bit2: [MAX_N + 2]i64
		applied := 0
		for middle in 0..event_count + 1 {
			for applied < middle {
				range_add(bit1[:], bit2[:], n, event_left[applied], event_right[applied], event_delta[applied])
				applied += 1
			}
			query := heads[middle]
			for query >= 0 {
				id := int(query)
				if range_sum(bit1[:], bit2[:], query_left[id], query_right[id]) >= query_target[id] {
					high[id] = i64(middle)
				} else {
					low[id] = i64(middle)
				}
				query = next_query[id]
			}
		}
	}

	result: i64 = 0
	for query in 0..<query_count {
		result += i64(query + 1) * (high[query] + 1)
	}
	return result
}
