module general_weighted_matching

const max_n = 16
const max_states = 1 << max_n
const max_output_words = 2 + max_n
const max_input_values = usize(2 + 3 * (max_n * (max_n - 1) / 2) + 1)
const max_weight = i64(1_000_000)

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'general_weighted_matching']
pub fn general_weighted_matching(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values { return -1 }
	unsafe {
		nv, mv := input[0], input[1]
		if nv < 1 || nv > max_n || mv < 0 || mv > nv * (nv - 1) / 2 { return -1 }
		n, m := int(nv), int(mv)
		if length != usize(2 + 3 * m) { return -1 }

		mut weights := []i64{len: max_n * max_n}
		mut present := []bool{len: max_n * max_n}
		mut cursor := 2
		for _ in 0 .. m {
			u_value, v_value, edge_weight := input[cursor], input[cursor + 1], input[cursor + 2]
			cursor += 3
			if u_value < 0 || u_value >= nv || v_value < 0 || v_value >= nv || u_value == v_value || edge_weight < 1 || edge_weight > max_weight { return -1 }
			u, v := int(u_value), int(v_value)
			uv, vu := u * max_n + v, v * max_n + u
			if present[uv] { return -1 }
			present[uv], present[vu] = true, true
			weights[uv], weights[vu] = edge_weight, edge_weight
		}

		mut dp := []i64{len: max_states}
		state_count := 1 << n
		for mask in 1 .. state_count {
			bit := mask & -mask
			mut vertex := 0
			for (bit >> vertex) != 1 { vertex++ }
			remainder := mask ^ bit
			dp[mask] = dp[remainder]
			for partner in vertex + 1 .. n {
				partner_bit := 1 << partner
				edge_index := vertex * max_n + partner
				if remainder & partner_bit == 0 || !present[edge_index] { continue }
				candidate := weights[edge_index] + dp[remainder ^ partner_bit]
				if candidate > dp[mask] { dp[mask] = candidate }
			}
		}

		mut words := []i64{len: max_output_words}
		mut pair_count := 0
		mut mask := state_count - 1
		for mask != 0 {
			bit := mask & -mask
			mut vertex := 0
			for (bit >> vertex) != 1 { vertex++ }
			remainder := mask ^ bit
			if dp[mask] == dp[remainder] {
				mask = remainder
				continue
			}
			mut selected := -1
			for partner in vertex + 1 .. n {
				partner_bit := 1 << partner
				edge_index := vertex * max_n + partner
				if remainder & partner_bit != 0 && present[edge_index] && weights[edge_index] + dp[remainder ^ partner_bit] == dp[mask] {
					selected = partner
					break
				}
			}
			if selected < 0 { return -1 }
			words[2 + 2 * pair_count], words[3 + 2 * pair_count] = i64(vertex), i64(selected)
			pair_count++
			mask = remainder ^ (1 << selected)
		}
		words[0], words[1] = i64(pair_count), dp[state_count - 1]
		output_words := 2 + 2 * pair_count
		output_bytes := usize(8 * output_words)
		if unsafe { output == nil } || capacity < output_bytes { return -2 }
		for word in 0 .. output_words { store_i64_le(mut output, 8 * word, words[word]) }
		return i64(output_bytes)
	}
}
