module magic_sequence

const max_n = 11
const fnv_offset_basis = u64(14_695_981_039_346_656_037)
const fnv_prime = u64(1_099_511_628_211)
const i64_result_mask = u64(0x7fff_ffff_ffff_ffff)

fn fnv_byte(mut hash u64, value u8) {
	hash = (hash ^ u64(value)) * fnv_prime
}

fn enumerate(n int, mut hash u64, hash_rows bool) u32 {
	if n == 0 { return 1 }
	mut vector := [11]u8{}
	mut frequencies := [11]u8{}
	mut next_candidate := [11]u8{}
	mut prefix_sum := [12]u8{}
	mut depth := 0
	mut solution_count := u32(0)

	for {
		if depth == n {
			mut is_magic := true
			for symbol in 0 .. n {
				if frequencies[symbol] != vector[symbol] {
					is_magic = false
					break
				}
			}
			if is_magic {
				solution_count++
				if hash_rows {
					for index in 0 .. n { fnv_byte(mut hash, vector[index]) }
				}
			}
			depth--
			frequencies[int(vector[depth])]--
			continue
		}

		candidate := next_candidate[depth]
		if int(candidate) >= n {
			next_candidate[depth] = 0
			if depth == 0 { break }
			depth--
			frequencies[int(vector[depth])]--
			continue
		}
		next_candidate[depth] = candidate + 1
		sum := int(prefix_sum[depth]) + int(candidate)
		if sum > n { continue }

		vector[depth] = candidate
		frequencies[int(candidate)]++
		prefix_sum[depth + 1] = u8(sum)
		depth++
		next_candidate[depth] = 0
	}
	return solution_count
}

@[export: 'magic_sequence']
pub fn magic_sequence(input &i64, length usize) i64 {
	if length != 1 { return -1 }
	unsafe {
		if input == nil || input[0] < 0 || input[0] > max_n { return -1 }
		n := int(input[0])
		mut hash := fnv_offset_basis
		fnv_byte(mut hash, u8(n))
		solution_count := enumerate(n, mut hash, false)
		for byte in 0 .. 4 { fnv_byte(mut hash, u8(solution_count >> u32(byte * 8))) }
		enumerate(n, mut hash, true)
		return i64(hash & i64_result_mask)
	}
}
