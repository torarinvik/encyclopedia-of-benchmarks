module interval_tree_point_stabbing

const max_n = 16
const max_q = 8
const tree_cap = 32
const max_output = 72

struct ItInterval {
mut:
	low  i64
	high i64
	id   int
}

@[export: 'interval_tree_point_stabbing']
pub fn interval_tree_point_stabbing(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 43 { return -1 }
		n64 := input[0]
		q64 := input[1]
		if n64 < 0 || n64 > max_n || q64 < 0 || q64 > max_q { return -1 }
		n := int(n64)
		q := int(q64)
		if length != usize(2 + 2 * n + q) { return -1 }
		mut sorted := [max_n]ItInterval{}
		mut cursor := 2
		for id in 0 .. n {
			low := input[cursor]
			high := input[cursor + 1]
			cursor += 2
			if low < -32 || low > 32 || high < -32 || high > 32 || low > high { return -1 }
			sorted[id] = ItInterval{low: low, high: high, id: id}
		}
		mut points := [max_q]i64{}
		for index in 0 .. q {
			points[index] = input[cursor]
			cursor++
			if points[index] < -32 || points[index] > 32 { return -1 }
		}
		mut index := 1
		for index < n {
			value := sorted[index]
			mut position := index
			for position > 0 {
				previous := sorted[position - 1]
				greater := previous.low > value.low ||
					(previous.low == value.low && previous.high > value.high) ||
					(previous.low == value.low && previous.high == value.high && previous.id > value.id)
				if !greater { break }
				sorted[position] = previous
				position--
			}
			sorted[position] = value
			index++
		}
		mut tree := [tree_cap]ItInterval{}
		mut used := [tree_cap]bool{}
		mut maximum := [tree_cap]i64{}
		mut firsts := [max_n]int{}
		mut lasts := [max_n]int{}
		mut nodes := [max_n]int{}
		for node in 0 .. tree_cap { maximum[node] = -9223372036854775807 - 1 }
		if n > 0 {
			mut top := 1
			firsts[0], lasts[0], nodes[0] = 0, n - 1, 0
			for top > 0 {
				top--
				first, last, node := firsts[top], lasts[top], nodes[top]
				if first > last || node >= tree_cap { continue }
				middle := first + (last - first) / 2
				tree[node] = sorted[middle]
				used[node] = true
				if middle + 1 <= last {
					firsts[top], lasts[top], nodes[top] = middle + 1, last, 2 * node + 2
					top++
				}
				if first <= middle - 1 {
					firsts[top], lasts[top], nodes[top] = first, middle - 1, 2 * node + 1
					top++
				}
			}
		}
		for node := tree_cap - 1; node >= 0; node-- {
			if !used[node] { continue }
			maximum[node] = tree[node].high
			left, right := 2 * node + 1, 2 * node + 2
			if left < tree_cap && used[left] && maximum[left] > maximum[node] { maximum[node] = maximum[left] }
			if right < tree_cap && used[right] && maximum[right] > maximum[node] { maximum[node] = maximum[right] }
		}
		mut masks := [max_q]i64{}
		for qi in 0 .. q {
			mut stack := [tree_cap]int{}
			mut top := 0
			if n > 0 { stack[0] = 0; top = 1 }
			for top > 0 {
				top--
				node := stack[top]
				if !used[node] || maximum[node] < points[qi] { continue }
				left, right := 2 * node + 1, 2 * node + 2
				if left < tree_cap && used[left] && maximum[left] >= points[qi] { stack[top] = left; top++ }
				if tree[node].low <= points[qi] && points[qi] <= tree[node].high { masks[qi] |= i64(1) << tree[node].id }
				if tree[node].low <= points[qi] && right < tree_cap && used[right] && maximum[right] >= points[qi] { stack[top] = right; top++ }
			}
		}
		bytes := (q + 1) * 8
		if output == nil || capacity < usize(bytes) { return -2 }
		mut staged := [max_output]u8{}
		mut header := u64(q)
		for byte in 0 .. 8 { staged[byte] = u8(header & 255); header >>= 8 }
		for qi in 0 .. q {
			mut bits := u64(masks[qi])
			for byte in 0 .. 8 { staged[(qi + 1) * 8 + byte] = u8(bits & 255); bits >>= 8 }
		}
		for byte in 0 .. bytes { output[byte] = staged[byte] }
		return i64(bytes)
	}
}
