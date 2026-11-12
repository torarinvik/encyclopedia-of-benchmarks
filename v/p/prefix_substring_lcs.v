module prefix_substring_lcs

const max_m = 32
const max_n = 32
const max_q = 64
const stride = max_n + 1
const max_input = 3 + max_m + max_n + 3 * max_q

struct Query { a int; b int; c int }

fn lowbit(value int) int { return value & -value }

fn fenwick_add(mut tree &int, position int, count int) {
	unsafe {
		mut index := position + 1
		for index <= count {
			tree[index]++
			index += lowbit(index)
		}
	}
}

fn fenwick_prefix(tree &int, exclusive int) int {
	unsafe {
		mut total := 0
		mut index := exclusive
		for index > 0 {
			total += tree[index]
			index -= lowbit(index)
		}
		return total
	}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'prefix_substring_lcs']
pub fn prefix_substring_lcs(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > usize(max_input) { return -1 }
		if input[0] < 1 || input[0] > max_m || input[1] < 1 || input[1] > max_n ||
			input[2] < 1 || input[2] > max_q { return -1 }
		m, n, q := int(input[0]), int(input[1]), int(input[2])
		if int(length) != 3 + m + n + 3 * q { return -1 }

		mut s := [max_m]int{}
		mut t := [max_n]int{}
		mut offset := 3
		for index in 0 .. m {
			code := input[offset]
			if code < 97 || code > 122 { return -1 }
			s[index] = int(code)
			offset++
		}
		for index in 0 .. n {
			code := input[offset]
			if code < 97 || code > 122 { return -1 }
			t[index] = int(code)
			offset++
		}
		mut queries := [max_q]Query{}
		mut query_head := [stride * stride]int{}
		mut query_next := [max_q]int{}
		for index in 0 .. stride * stride { query_head[index] = -1 }
		for index in 0 .. q {
			a, b, c_value := input[offset], input[offset + 1], input[offset + 2]
			if a < 0 || a > i64(m) || b < 0 || b > c_value || c_value > i64(n) { return -1 }
			queries[index] = Query{int(a), int(b), int(c_value)}
			key := queries[index].a * stride + queries[index].b
			query_next[index] = query_head[key]
			query_head[key] = index
			offset += 3
		}
		output_bytes := 8 * q
		if output == nil || capacity < usize(output_bytes) { return -2 }

		mut horizontal := [stride * stride]int{}
		mut vertical := [stride * stride]int{}
		for j in 0 .. n + 1 { horizontal[j] = j }
		for i in 1 .. m + 1 {
			for j in 1 .. n + 1 {
				above := horizontal[(i - 1) * stride + j]
				left := vertical[i * stride + j - 1]
				if s[i - 1] == t[j - 1] {
					horizontal[i * stride + j] = left
					vertical[i * stride + j] = above
				} else {
					if above > left { horizontal[i * stride + j] = above } else { horizontal[i * stride + j] = left }
					if above < left { vertical[i * stride + j] = above } else { vertical[i * stride + j] = left }
				}
			}
		}
		mut answers := [max_q]int{}
		for a in 0 .. m + 1 {
			mut value_head := [stride]int{}
			mut value_next := [stride]int{}
			for value in 0 .. n + 1 { value_head[value] = -1 }
			for position in 0 .. n + 1 {
				value := horizontal[a * stride + position]
				value_next[position] = value_head[value]
				value_head[value] = position
			}
			mut fenwick := [stride + 1]int{}
			for b in 0 .. n + 1 {
				mut position := value_head[b]
				for position >= 0 {
					fenwick_add(&fenwick[0], position, n + 1)
					position = value_next[position]
				}
				mut qi := query_head[a * stride + b]
				for qi >= 0 {
					query := queries[qi]
					answers[qi] = fenwick_prefix(&fenwick[0], query.c + 1) - fenwick_prefix(&fenwick[0], query.b + 1)
					qi = query_next[qi]
				}
			}
		}
		for index in 0 .. q { store_i64_le(mut output, 8 * index, i64(answers[index])) }
		return i64(output_bytes)
	}
}
