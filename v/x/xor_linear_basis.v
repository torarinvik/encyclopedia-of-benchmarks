module xor_linear_basis

const max_operations = 64
const max_insertions = 16
const max_input_values = 1 + 2 * max_operations
const bit_count = 63

fn insert_value(mut basis [bit_count]u64, value u64) {
	mut reduced := value
	for bit := bit_count - 1; bit >= 0 && reduced != 0; bit-- {
		if ((reduced >> bit) & 1) == 0 { continue }
		if basis[bit] == 0 { basis[bit] = reduced; return }
		reduced ^= basis[bit]
	}
}

fn maximum_value(basis [bit_count]u64) u64 {
	mut best := u64(0)
	for bit := bit_count - 1; bit >= 0; bit-- {
		candidate := best ^ basis[bit]
		if candidate > best { best = candidate }
	}
	return best
}

fn contains_value(basis [bit_count]u64, raw_value u64) bool {
	mut value := raw_value
	for bit := bit_count - 1; bit >= 0; bit-- {
		if ((value >> bit) & 1) == 0 { continue }
		if basis[bit] == 0 { return false }
		value ^= basis[bit]
	}
	return value == 0
}

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'xor_linear_basis']
pub fn xor_linear_basis(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 2 || length > usize(max_input_values) { return -1 }
	unsafe {
		if input == nil { return -1 }
		qv := input[0]
		if qv < 1 || qv > max_operations { return -1 }
		q := int(qv)
		mut basis := [bit_count]u64{}
		mut results := [max_operations]i64{}
		mut result_count := 0
		mut cursor := 1
		mut insertion_count := 0
		for _ in 0 .. q {
			if cursor >= int(length) { return -1 }
			kind := input[cursor]
			cursor++
			if kind == 0 || kind == 2 {
				if cursor >= int(length) { return -1 }
				raw := input[cursor]
				cursor++
				if raw < 0 { return -1 }
				value := u64(raw)
				if kind == 0 {
					insertion_count++
					if insertion_count > max_insertions { return -1 }
					insert_value(mut basis, value)
				} else {
					if contains_value(basis, value) { results[result_count] = 1 } else { results[result_count] = 0 }
					result_count++
				}
			} else if kind == 1 {
				results[result_count] = i64(maximum_value(basis))
				result_count++
			} else {
				return -1
			}
		}
		if cursor != int(length) { return -1 }
		output_bytes := 8 * result_count
		if output_bytes == 0 { return 0 }
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for result in 0 .. result_count { store_le(mut output, 8 * result, results[result]) }
		return i64(output_bytes)
	}
}
