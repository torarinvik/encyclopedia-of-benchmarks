module mo

const max_n = 64
const max_q = 64
const max_value = 255
const max_parseable_input_words = 2 + max_n + 2 * max_q + 1
const max_output_bytes = 4 * max_q

struct Query {
mut:
	left int
	right int
	index int
}

fn ceil_sqrt(n int) int {
	mut block := 1
	for block * block < n { block++ }
	return block
}

fn before(a Query, b Query, block_size int) bool {
	a_block, b_block := a.left / block_size, b.left / block_size
	if a_block != b_block { return a_block < b_block }
	return a.right < b.right
}

fn put_i32_le(mut output &u8, offset int, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'mo']
pub fn mo(input &i32, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_parseable_input_words) { return -1 }
		n_raw := input[0]
		if n_raw < 1 || n_raw > max_n { return -1 }
		n := int(n_raw)
		q_offset := 1 + n
		if int(length) <= q_offset { return -1 }
		q_raw := input[q_offset]
		if q_raw < 0 || q_raw > max_q { return -1 }
		q_count := int(q_raw)
		if int(length) != q_offset + 1 + 2 * q_count { return -1 }
		for i in 0 .. n { if input[1 + i] < 0 || input[1 + i] > max_value { return -1 } }
		mut queries := [max_q]Query{}
		for i in 0 .. q_count {
			left_raw, right_raw := input[q_offset + 1 + 2 * i], input[q_offset + 2 + 2 * i]
			if left_raw < 1 || right_raw < left_raw || right_raw > n_raw { return -1 }
			queries[i] = Query{left: int(left_raw - 1), right: int(right_raw - 1), index: i}
		}
		bytes := 4 * q_count
		if output == nil || capacity < usize(bytes) { return -2 }
		block_size := ceil_sqrt(n)
		for i in 1 .. q_count {
			value := queries[i]
			mut j := i
			for j > 0 && before(value, queries[j - 1], block_size) { queries[j] = queries[j - 1]; j-- }
			queries[j] = value
		}
		mut frequencies := [max_value + 1]i32{}
		mut answers := [max_q]i32{}
		mut distinct, left, right := 0, 0, 0
		for i in 0 .. q_count {
			query := queries[i]
			for left < query.left {
				value := int(input[1 + left]); left++; frequencies[value]--
				if frequencies[value] == 0 { distinct-- }
			}
			for left > query.left {
				left--; value := int(input[1 + left]); frequencies[value]++
				if frequencies[value] == 1 { distinct++ }
			}
			for right <= query.right {
				value := int(input[1 + right]); frequencies[value]++
				if frequencies[value] == 1 { distinct++ }
				right++
			}
			for right > query.right + 1 {
				right--; value := int(input[1 + right]); frequencies[value]--
				if frequencies[value] == 0 { distinct-- }
			}
			answers[query.index] = i32(distinct)
		}
		if bytes == 0 { return 0 }
		mut buffer := [max_output_bytes]u8{}
		for i in 0 .. q_count { put_i32_le(mut buffer[0], i * 4, answers[i]) }
		for i in 0 .. bytes { output[i] = buffer[i] }
		return i64(bytes)
	}
}
