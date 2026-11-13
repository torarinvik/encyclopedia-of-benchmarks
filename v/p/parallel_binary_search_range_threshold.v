const max_n = 16
const max_events = 32
const max_queries = 32
const max_parseable_length = 196

fn bit_add(mut bit [max_n + 2]i64, start int, delta i64, limit int) {
	mut index := start
	for index <= limit + 1 {
		bit[index] += delta
		index += index & -index
	}
}

fn bit_sum(bit [max_n + 2]i64, start int) i64 {
	mut index := start
	mut total := i64(0)
	for index > 0 {
		total += bit[index]
		index -= index & -index
	}
	return total
}

fn range_add(mut bit1 [max_n + 2]i64, mut bit2 [max_n + 2]i64,
	n int, left int, right int, delta i64) {
	lo := left + 1
	hi := right + 1
	bit_add(mut bit1, lo, delta, n)
	bit_add(mut bit1, hi + 1, -delta, n)
	bit_add(mut bit2, lo, delta * i64(lo - 1), n)
	bit_add(mut bit2, hi + 1, -delta * i64(hi), n)
}

fn prefix_sum(bit1 [max_n + 2]i64, bit2 [max_n + 2]i64, count int) i64 {
	return i64(count) * bit_sum(bit1, count) - bit_sum(bit2, count)
}

fn range_sum(bit1 [max_n + 2]i64, bit2 [max_n + 2]i64, left int, right int) i64 {
	return prefix_sum(bit1, bit2, right + 1) - prefix_sum(bit1, bit2, left)
}

@[export: 'parallel_binary_search_range_threshold']
pub fn parallel_binary_search_range_threshold(input &i64, length usize) i64 {
	if length < 3 || length > max_parseable_length { return -1 }
	unsafe {
		if input == nil || input[0] < 1 || input[0] > max_n || input[1] < 0 ||
			input[1] > max_events || input[2] < 0 || input[2] > max_queries { return -1 }
		n := int(input[0])
		event_count := int(input[1])
		query_count := int(input[2])
		if length != usize(3 + 3 * event_count + 3 * query_count) { return -1 }

		mut event_left := [max_events]int{}
		mut event_right := [max_events]int{}
		mut event_delta := [max_events]i64{}
		mut query_left := [max_queries]int{}
		mut query_right := [max_queries]int{}
		mut query_target := [max_queries]i64{}
		mut cursor := 3
		for event in 0 .. event_count {
			left := input[cursor]
			right := input[cursor + 1]
			delta := input[cursor + 2]
			cursor += 3
			if left < 0 || left > right || right >= i64(n) || delta < 0 || delta > 1000 { return -1 }
			event_left[event] = int(left)
			event_right[event] = int(right)
			event_delta[event] = delta
		}
		for query in 0 .. query_count {
			left := input[cursor]
			right := input[cursor + 1]
			target := input[cursor + 2]
			cursor += 3
			if left < 0 || left > right || right >= i64(n) || target < 1 || target > 512000 { return -1 }
			query_left[query] = int(left)
			query_right[query] = int(right)
			query_target[query] = target
		}

		mut low := [max_queries]i64{}
		mut high := [max_queries]i64{}
		mut next_query := [max_queries]i64{}
		for query in 0 .. query_count { high[query] = i64(event_count + 1) }
		for {
			mut heads := [max_events + 1]i64{}
			for time in 0 .. max_events + 1 { heads[time] = -1 }
			for query in 0 .. query_count { next_query[query] = -1 }
			mut active := false
			for query in 0 .. query_count {
				if high[query] - low[query] > 1 {
					active = true
					middle := int((low[query] + high[query]) / 2)
					next_query[query] = heads[middle]
					heads[middle] = i64(query)
				}
			}
			if !active { break }

			mut bit1 := [max_n + 2]i64{}
			mut bit2 := [max_n + 2]i64{}
			mut applied := 0
			for middle in 0 .. event_count + 1 {
				for applied < middle {
					range_add(mut bit1, mut bit2, n, event_left[applied], event_right[applied], event_delta[applied])
					applied++
				}
				mut query := heads[middle]
				for query >= 0 {
					id := int(query)
					if range_sum(bit1, bit2, query_left[id], query_right[id]) >= query_target[id] {
						high[id] = i64(middle)
					} else {
						low[id] = i64(middle)
					}
					query = next_query[id]
				}
			}
		}

		mut result := i64(0)
		for query in 0 .. query_count { result += i64(query + 1) * (high[query] + 1) }
		return result
	}
}
