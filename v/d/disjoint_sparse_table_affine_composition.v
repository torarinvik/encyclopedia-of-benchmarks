module disjoint_sparse_table_affine_composition

const modulus = i64(1000000007)
const max_n = 32
const max_q = 32
const max_levels = 5

struct Affine {
	a i64
	b i64
}

fn combine(left Affine, right Affine) Affine {
	return Affine{
		a: (right.a * left.a) % modulus
		b: (right.a * left.b + right.b) % modulus
	}
}

fn put_word(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'disjoint_sparse_table_affine_composition']
pub fn disjoint_sparse_table_affine_composition(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if length < 2 || length > 130 || unsafe { input == nil } { return -1 }
	unsafe {
		n_value, q_value := input[0], input[1]
		if n_value < 1 || n_value > max_n || q_value < 1 || q_value > max_q { return -1 }
		n, q := int(n_value), int(q_value)
		if int(length) != 2 + 2 * n + 2 * q { return -1 }

		mut maps := [max_n]Affine{}
		mut left, mut right := [max_q]int{}, [max_q]int{}
		mut cursor := 2
		for index in 0 .. n {
			a, b := input[cursor], input[cursor + 1]
			cursor += 2
			if a < 0 || a >= modulus || b < 0 || b >= modulus { return -1 }
			maps[index] = Affine{a: a, b: b}
		}
		for query in 0 .. q {
			lo, hi := input[cursor], input[cursor + 1]
			cursor += 2
			if lo < 0 || lo > hi || hi >= n_value { return -1 }
			left[query], right[query] = int(lo), int(hi)
		}
		output_bytes := q * 16
		if output == nil || capacity < usize(output_bytes) { return -2 }

		mut table := [max_levels][max_n]Affine{}
		mut levels, mut span := 0, 1
		for span < n { levels++; span *= 2 }
		for level in 0 .. levels {
			half := 1 << level
			width := half * 2
			mut start := 0
			for start < n {
				mut middle, mut ending := start + half, start + width
				if middle > n { middle = n }
				if ending > n { ending = n }
				if middle > start {
					table[level][middle - 1] = maps[middle - 1]
					mut index := middle - 1
					for index > start {
						table[level][index - 1] = combine(maps[index - 1], table[level][index])
						index--
					}
				}
				if middle < ending {
					table[level][middle] = maps[middle]
					for index in middle + 1 .. ending {
						table[level][index] = combine(table[level][index - 1], maps[index])
					}
				}
				start += width
			}
		}
		for query in 0 .. q {
			mut answer := Affine{}
			if left[query] == right[query] {
				answer = maps[left[query]]
			} else {
				mut difference := left[query] ^ right[query]
				mut level := 0
				for difference > 1 { difference >>= 1; level++ }
				answer = combine(table[level][left[query]], table[level][right[query]])
			}
			put_word(mut output, query * 16, answer.a)
			put_word(mut output, query * 16 + 8, answer.b)
		}
		return i64(output_bytes)
	}
}
