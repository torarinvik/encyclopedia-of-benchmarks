module ekg_sequence

const max_n = 8
const max_candidate = 40320

fn gcd_i64(left i64, right i64) i64 {
	mut a := left
	mut b := right
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

@[export: 'ekg_sequence']
pub fn ekg_sequence(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 2 { return -1 }
		requested := input[0]
		if length != 1 || requested < 1 || requested > max_n { return -1 }

		mut terms := [max_n]i64{}
		mut used := [max_candidate + 1]u8{}
		terms[0] = 1
		used[1] = 1
		mut term_count := 1
		if requested >= 2 {
			terms[1] = 2
			used[2] = 1
			term_count = 2
		}

		for term_count < int(requested) {
			position := i64(term_count + 1)
			previous := terms[term_count - 1]
			search_bound := previous * position
			mut candidate := i64(1)
			for candidate <= search_bound {
				if used[int(candidate)] == 0 && gcd_i64(previous, candidate) > 1 { break }
				candidate++
			}
			if candidate > search_bound { return -1 }
			terms[term_count] = candidate
			used[int(candidate)] = 1
			term_count++
		}

		output_bytes := int(requested) * 8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for index in 0 .. term_count {
			bits := u64(terms[index])
			for byte in 0 .. 8 {
				output[index * 8 + byte] = u8((bits >> (byte * 8)) & 255)
			}
		}
		return i64(output_bytes)
	}
}
