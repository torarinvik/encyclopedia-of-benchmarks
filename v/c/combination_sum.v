const max_candidates = 8
const max_target = 20
const max_packed_words = 4096

struct Search {
	candidates &i64
	count int
	mut:
	path [20]i64
	packed [4096]i64
	used int = 1
}

fn enumerate(mut search Search, start int, remaining i64, depth int) {
	if remaining == 0 {
		search.packed[search.used] = i64(depth)
		search.used++
		for i in 0 .. depth {
			search.packed[search.used] = search.path[i]
			search.used++
		}
		search.packed[0]++
		return
	}
	for i := start; i < search.count; i++ {
		candidate := unsafe { search.candidates[i] }
		if candidate > remaining { break }
		search.path[depth] = candidate
		enumerate(mut search, i, remaining - candidate, depth + 1)
	}
}

fn put_i64(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'combination_sum']
pub fn combination_sum(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 3 || isnil(input) { return -1 }
	count_value := unsafe { input[0] }
	target := unsafe { input[1] }
	if count_value < 1 || count_value > max_candidates || target < 0 || target > max_target { return -1 }
	count := int(count_value)
	if length != usize(count + 2) { return -1 }
	for i in 0 .. count {
		candidate := unsafe { input[i + 2] }
		if candidate < 1 || candidate > 24 || (i > 0 && unsafe { input[i + 1] } >= candidate) { return -1 }
	}

	mut search := Search{candidates: unsafe { &input[2] }, count: count}
	enumerate(mut search, 0, target, 0)
	required := search.used * 8
	if capacity < required || isnil(output) { return -2 }
	for i in 0 .. search.used { put_i64(mut output, i * 8, search.packed[i]) }
	return i64(required)
}
