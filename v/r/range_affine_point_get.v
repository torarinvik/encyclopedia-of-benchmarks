module range_affine_point_get

const max_n = 256
const max_q = 256
const max_base = 256
const max_tree = 2 * max_base
const max_parseable_input = usize(2 + max_n + 5 * max_q + 1)
const modulus = i64(998_244_353)

struct Operation { kind i64; left i64; right i64; multiplier i64; offset i64 }

fn apply_tag(mut mul &i64, mut add &i64, node int, multiplier i64, offset i64) {
	unsafe {
		add[node] = (multiplier * add[node] + offset) % modulus
		mul[node] = (multiplier * mul[node]) % modulus
	}
}

fn push(mut mul &i64, mut add &i64, node int) {
	unsafe {
		if mul[node] != 1 || add[node] != 0 {
			multiplier, offset := mul[node], add[node]
			apply_tag(mut mul, mut add, 2 * node, multiplier, offset)
			apply_tag(mut mul, mut add, 2 * node + 1, multiplier, offset)
			mul[node] = 1
			add[node] = 0
		}
	}
}

fn range_apply(mut mul &i64, mut add &i64, node int, segment_left int,
		segment_right int, left int, right int, multiplier i64, offset i64) {
	unsafe {
		if right <= segment_left || segment_right <= left { return }
		if left <= segment_left && segment_right <= right {
			apply_tag(mut mul, mut add, node, multiplier, offset)
			return
		}
		push(mut mul, mut add, node)
		middle := segment_left + (segment_right - segment_left) / 2
		range_apply(mut mul, mut add, 2 * node, segment_left, middle, left, right, multiplier, offset)
		range_apply(mut mul, mut add, 2 * node + 1, middle, segment_right, left, right, multiplier, offset)
	}
}

fn point_get(mut mul &i64, mut add &i64, initial &i64, node int,
		segment_left int, segment_right int, index int) i64 {
	unsafe {
		if segment_right - segment_left == 1 { return (mul[node] * initial[index] + add[node]) % modulus }
		push(mut mul, mut add, node)
		middle := segment_left + (segment_right - segment_left) / 2
		if index < middle { return point_get(mut mul, mut add, initial, 2 * node, segment_left, middle, index) }
		return point_get(mut mul, mut add, initial, 2 * node + 1, middle, segment_right, index)
	}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
	}
}

@[export: 'range_affine_point_get']
pub fn range_affine_point_get(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_parseable_input { return -1 }
	unsafe {
		nv, qv := input[0], input[1]
		if nv < 1 || nv > max_n || qv < 0 || qv > max_q { return -1 }
		n, q := int(nv), int(qv)
		if 2 + n > int(length) { return -1 }
		mut initial := [max_n]i64{}
		mut operations := [max_q]Operation{}
		for index in 0 .. n {
			initial[index] = input[2 + index]
			if initial[index] < 0 || initial[index] >= modulus { return -1 }
		}
		mut cursor, query_count := 2 + n, 0
		for index in 0 .. q {
			if cursor >= int(length) { return -1 }
			kind := input[cursor]
			cursor++
			if kind == 0 {
				if cursor + 4 > int(length) { return -1 }
				left, right := input[cursor], input[cursor + 1]
				multiplier, offset := input[cursor + 2], input[cursor + 3]
				cursor += 4
				if left < 0 || left >= right || right > nv || multiplier < 1 || multiplier >= modulus || offset < 0 || offset >= modulus { return -1 }
				operations[index] = Operation{kind, left, right, multiplier, offset}
			} else if kind == 1 {
				if cursor >= int(length) { return -1 }
				point := input[cursor]
				cursor++
				if point < 0 || point >= nv { return -1 }
				operations[index] = Operation{kind, point, 0, 0, 0}
				query_count++
			} else { return -1 }
		}
		if cursor != int(length) { return -1 }
		output_bytes := 8 * query_count
		if output_bytes > 0 && (output == nil || capacity < usize(output_bytes)) { return -2 }
		mut base := 1
		for base < n { base *= 2 }
		mut mul := [max_tree]i64{}
		mut add := [max_tree]i64{}
		for node in 0 .. max_tree { mul[node] = 1 }
		mut answer := 0
		for index in 0 .. q {
			op := operations[index]
			if op.kind == 0 {
				range_apply(mut mul[0], mut add[0], 1, 0, base, int(op.left), int(op.right), op.multiplier, op.offset)
			} else {
				value := point_get(mut mul[0], mut add[0], initial[0], 1, 0, base, int(op.left))
				store_i64_le(mut output, 8 * answer, value)
				answer++
			}
		}
		return i64(output_bytes)
	}
}
