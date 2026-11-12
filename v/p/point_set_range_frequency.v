module point_set_range_frequency

const max_n = 64
const max_q = 64
const max_values = max_n + max_q
const stride = max_n + 1
const max_tree = max_values * stride
const max_parseable_input = usize(2 + max_n + 4 * max_q + 1)
const max_value = i64(1_000_000)

struct Operation { kind i64; a i64; b i64; c i64 }

fn lowbit(value int) int { return value & -value }

fn lower_bound(values &i64, count int, target i64) int {
	unsafe {
		mut left, right := 0, count
		for left < right {
			middle := left + (right-left)/2
			if values[middle] < target { left = middle+1 } else { right = middle }
		}
		return left
	}
}

fn sort_unique(mut values &i64, count int) int {
	unsafe {
		for index in 1 .. count {
			value := values[index]
			mut position := index
			for position > 0 && values[position-1] > value {
				values[position] = values[position-1]
				position--
			}
			values[position] = value
		}
		mut unique_count := 0
		for index in 0 .. count {
			if unique_count == 0 || values[index] != values[unique_count-1] {
				values[unique_count] = values[index]
				unique_count++
			}
		}
		return unique_count
	}
}

fn fenwick_add(mut tree &i64, value_id int, position int, n int, delta i64) {
	unsafe {
		mut index := position+1
		row := value_id*stride
		for index <= n {
			tree[row+index] += delta
			index += lowbit(index)
		}
	}
}

fn fenwick_prefix(tree &i64, value_id int, count int) i64 {
	unsafe {
		mut index := count
		row := value_id*stride
		mut total: i64 = 0
		for index > 0 {
			total += tree[row+index]
			index -= lowbit(index)
		}
		return total
	}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
	}
}

@[export: 'point_set_range_frequency']
pub fn point_set_range_frequency(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_parseable_input { return -1 }
	unsafe {
		nv, qv := input[0], input[1]
		if nv < 1 || nv > max_n || qv < 0 || qv > max_q { return -1 }
		n, q := int(nv), int(qv)
		if 2+n > int(length) { return -1 }
		mut values := [max_values]i64{}
		mut initial := [max_n]i64{}
		mut operations := [max_q]Operation{}
		mut value_count := 0
		for index in 0 .. n {
			value := input[2+index]
			if value < 0 || value > max_value { return -1 }
			initial[index] = value
			values[value_count] = value
			value_count++
		}
		mut cursor, query_count := 2+n, 0
		for index in 0 .. q {
			if cursor >= int(length) { return -1 }
			kind := input[cursor]
			cursor++
			if kind == 0 {
				if cursor+2 > int(length) { return -1 }
				position, value := input[cursor], input[cursor+1]
				cursor += 2
				if position < 0 || position >= nv || value < 0 || value > max_value { return -1 }
				operations[index] = Operation{kind, position, value, 0}
				values[value_count] = value
				value_count++
			} else if kind == 1 {
				if cursor+3 > int(length) { return -1 }
				left, right, value := input[cursor], input[cursor+1], input[cursor+2]
				cursor += 3
				if left < 0 || left > right || right > nv || value < 0 || value > max_value { return -1 }
				operations[index] = Operation{kind, left, right, value}
				query_count++
			} else { return -1 }
		}
		if cursor != int(length) { return -1 }
		output_bytes := 8*query_count
		if output_bytes > 0 && (output == nil || capacity < usize(output_bytes)) { return -2 }

		unique_count := sort_unique(&values[0], value_count)
		mut tree := [max_tree]i64{}
		mut current := [max_n]int{}
		for position in 0 .. n {
			current[position] = lower_bound(&values[0], unique_count, initial[position])
			fenwick_add(mut tree[0], current[position], position, n, 1)
		}
		mut answer := 0
		for index in 0 .. q {
			op := operations[index]
			if op.kind == 0 {
				position := int(op.a)
				next := lower_bound(&values[0], unique_count, op.b)
				if current[position] != next {
					fenwick_add(mut tree[0], current[position], position, n, -1)
					fenwick_add(mut tree[0], next, position, n, 1)
					current[position] = next
				}
			} else {
				id := lower_bound(&values[0], unique_count, op.c)
				mut count: i64 = 0
				if id < unique_count && values[id] == op.c {
					count = fenwick_prefix(tree[0], id, int(op.b))-fenwick_prefix(tree[0], id, int(op.a))
				}
				store_i64_le(mut output, answer*8, count)
				answer++
			}
		}
		return i64(output_bytes)
	}
}
