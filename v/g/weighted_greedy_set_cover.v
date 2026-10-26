module weighted_greedy_set_cover

const max_m = 16
const max_input = 34
const max_output = 136

@[export: 'weighted_greedy_set_cover']
pub fn weighted_greedy_set_cover(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 1 || n64 > 16 || m64 < 1 || m64 > 16 || length != usize(2 + 2*m64) { return -1 }
		n, m := int(n64), int(m64)
		full := (u64(1) << n) - 1
		mut weights := [max_m]i64{init: 0}
		mut masks := [max_m]u64{init: 0}
		mut union_mask := u64(0)
		for set in 0 .. m {
			weights[set] = input[2 + set]
			mask_value := input[2 + m + set]
			if weights[set] < 0 || weights[set] > 10000 || mask_value < 0 || (u64(mask_value) & ~full) != 0 { return -1 }
			masks[set] = u64(mask_value)
			union_mask |= masks[set]
		}
		if union_mask != full { return -1 }

		mut covered := u64(0)
		mut selected := [max_m]int{init: 0}
		mut selected_count := 0
		for covered != full {
			mut best := -1
			mut best_gain := 0
			for set in 0 .. m {
				gain := int(bit_count(masks[set] & ~covered))
				if gain == 0 { continue }
				if best < 0 || weights[set]*i64(best_gain) < weights[best]*i64(gain) {
					best, best_gain = set, gain
				}
			}
			if best < 0 { return -1 }
			selected[selected_count] = best
			selected_count++
			covered |= masks[best]
		}
		output_bytes := 8*(selected_count+1)
		if output == nil || capacity < output_bytes { return -2 }
		mut staged := [max_output]u8{init: 0}
		values := []i64{len: selected_count+1, init: 0}
		values[0] = i64(selected_count)
		for index in 0 .. selected_count { values[index+1] = i64(selected[index]) }
		for index, value in values {
			bits := u64(value)
			for byte in 0 .. 8 { staged[8*index+byte] = u8((bits >> (8*byte)) & 255) }
		}
		for index in 0 .. output_bytes { output[index] = staged[index] }
		return i64(output_bytes)
	}
}

fn bit_count(value u64) int {
	mut bits := value
	mut count := 0
	for bits != 0 { bits &= bits-1; count++ }
	return count
}
