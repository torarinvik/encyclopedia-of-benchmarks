module static_range_lis_query

const max_n = 128
const max_q = 32

fn lower_bound(tails []i64, count int, value i64) int {
	mut lo := 0
	mut hi := count
	for lo < hi {
		mid := lo + (hi - lo) / 2
		if tails[mid] < value { lo = mid + 1 } else { hi = mid }
	}
	return lo
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'static_range_lis_query']
pub fn static_range_lis_query(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 195 { return -1 }
	nv := unsafe { input[0] }
	qv := unsafe { input[1] }
	if nv < 1 || nv > max_n || qv < 1 || qv > max_q { return -1 }
	n := int(nv)
	q := int(qv)
	if length != usize(2 + n + 2 * q) { return -1 }
	mut permutation := []i64{len: max_n}
	mut seen := []bool{len: max_n}
	mut left := []i64{len: max_q}
	mut right := []i64{len: max_q}
	mut answers := []i64{len: max_q}
	mut tails := []i64{len: max_n}
	for i in 0 .. n {
		value := unsafe { input[2 + i] }
		if value < 0 || value >= nv || seen[int(value)] { return -1 }
		seen[int(value)] = true
		permutation[i] = value
	}
	mut off := 2 + n
	for k in 0 .. q {
		left[k] = unsafe { input[off] }
		right[k] = unsafe { input[off + 1] }
		off += 2
		if left[k] < 0 || left[k] > right[k] || right[k] > nv { return -1 }
	}
	for k in 0 .. q {
		mut count := 0
		for i := int(left[k]); i < int(right[k]); i++ {
			at := lower_bound(tails, count, permutation[i])
			tails[at] = permutation[i]
			if at == count { count++ }
		}
		answers[k] = i64(count)
	}
	bytes := 8 * q
	if unsafe { output == nil } || int(capacity) < bytes { return -2 }
	for k in 0 .. q { put_i64_le(mut output, 8 * k, answers[k]) }
	return i64(bytes)
}
