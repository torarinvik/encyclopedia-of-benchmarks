module generate_sub_sets

const max_items = 12
const max_safe = i64(9_007_199_254_740_991)

fn generate_sub_sets_put32(mut output &u8, mut pos int, value u32) {
	mut bits := value
	for _ in 0 .. 4 { unsafe { output[pos] = u8(bits & 255) }; pos++; bits >>= 8 }
}
fn generate_sub_sets_put64(mut output &u8, mut pos int, value i64) {
	mut bits := u64(value)
	for _ in 0 .. 8 { unsafe { output[pos] = u8(bits & 255) }; pos++; bits >>= 8 }
}

@[export: 'generate_sub_sets']
pub fn generate_sub_sets(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_items + 1 { return -1 }
	n_arg := unsafe { input[0] }
	if n_arg < 0 || n_arg > max_items { return -1 }
	n := int(n_arg)
	if length != usize(n + 1) { return -1 }
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < -max_safe || value > max_safe { return -1 }
	}
	subsets := 1 << n
	total_items := if n == 0 { 0 } else { n * (subsets / 2) }
	needed := 4 + 4 * subsets + 8 * total_items
	if unsafe { output == nil } || capacity < usize(needed) { return -2 }
	mut pos := 0
	generate_sub_sets_put32(mut output, mut pos, u32(subsets))
	for mask in 0 .. subsets {
		mut count := u32(0)
		for j in 0 .. n { if (mask & (1 << j)) != 0 { count++ } }
		generate_sub_sets_put32(mut output, mut pos, count)
		for j in 0 .. n {
			if (mask & (1 << j)) != 0 {
				generate_sub_sets_put64(mut output, mut pos, unsafe { input[j + 1] })
			}
		}
	}
	return i64(pos)
}
