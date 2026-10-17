module sparse_table

const max_n = 12345
const max_levels = 14
const max_parseable_input_length = 12348

@[export: 'sparse_table']
pub fn sparse_table(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > usize(max_parseable_input_length) { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 12344 { return -1 }
		n := int(input[0])
		if length != usize(n + 3) { return -1 }
		left64, right64 := input[n + 1], input[n + 2]
		if left64 < 0 || right64 < left64 || right64 >= i64(n) { return -1 }
		left, right := int(left64), int(right64)
		mut values := [max_n]i64{}
		for index in 0 .. n { values[index] = input[index + 1] }
		mut logs := [max_n + 1]int{}
		for size := 2; size <= n; size++ { logs[size] = logs[size / 2] + 1 }
		mut table := [max_levels * max_n]i32{}
		for index in 0 .. n { table[index] = i32(index) }
		for level := 1; level <= logs[n]; level++ {
			span := 1 << level
		half := span >> 1
			for index := 0; index + span <= n; index++ {
				first := int(table[(level - 1) * max_n + index])
				second := int(table[(level - 1) * max_n + index + half])
				if values[first] <= values[second] { table[level * max_n + index] = i32(first) } else { table[level * max_n + index] = i32(second) }
			}
		}
		query_length := right - left + 1
		level := logs[query_length]
		span := 1 << level
		first := int(table[level * max_n + left])
		second := int(table[level * max_n + right - span + 1])
		if values[first] <= values[second] { return i64(first) }
		return i64(second)
	}
}
