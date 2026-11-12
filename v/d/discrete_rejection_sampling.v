const max_categories = 8
const max_samples = 8
const max_attempts = 32
const max_input_values = 83

@[export: 'discrete_rejection_sampling']
pub fn discrete_rejection_sampling(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input_values { return -1 }
		n64 := input[0]
		samples64 := input[1]
		attempts64 := input[2]
		if n64 < 1 || n64 > max_categories || samples64 < 1 || samples64 > max_samples ||
			attempts64 < 1 || attempts64 > max_attempts { return -1 }
		n := int(n64)
		wanted := int(samples64)
		attempts := int(attempts64)
		if length != usize(3 + 2*n + 2*attempts) { return -1 }

		mut target := []u64{len: n, init: 0}
		mut proposal := []u64{len: n, init: 0}
		mut cumulative := []u64{len: n, init: 0}
		mut target_total := u64(0)
		mut proposal_total := u64(0)
		for i in 0 .. n {
			weight := input[3+i]
			q_weight := input[3+n+i]
			if weight < 1 || weight > 20 || q_weight < 1 || q_weight > 20 { return -1 }
			target[i] = u64(weight)
			proposal[i] = u64(q_weight)
			target_total += target[i]
			proposal_total += proposal[i]
			cumulative[i] = proposal_total
		}

		mut envelope := u64(1)
		for i in 0 .. n {
			numerator := target[i] * proposal_total
			denominator := target_total * proposal[i]
			ratio_ceiling := (numerator + denominator - 1) / denominator
			if ratio_ceiling > envelope { envelope = ratio_ceiling }
		}

		tape_offset := 3 + 2*n
		for attempt in 0 .. attempts {
			proposal_draw := input[tape_offset+2*attempt]
			acceptance_draw := input[tape_offset+2*attempt+1]
			if proposal_draw < 0 || u64(proposal_draw) >= proposal_total || acceptance_draw < 0 { return -1 }
			mut category := 0
			for category < n && cumulative[category] <= u64(proposal_draw) { category++ }
			acceptance_range := target_total * proposal[category] * envelope
			if u64(acceptance_draw) >= acceptance_range { return -1 }
		}

		output_bytes := 16 * wanted
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := []i64{len: 2*wanted, init: 0}
		mut produced := 0
		mut attempts_since_acceptance := 0
		for attempt in 0 .. attempts {
			attempts_since_acceptance++
			proposal_draw := u64(input[tape_offset+2*attempt])
			acceptance_draw := u64(input[tape_offset+2*attempt+1])
			mut category := 0
			for category < n && cumulative[category] <= proposal_draw { category++ }
			if acceptance_draw < i64(target[category] * proposal_total) {
				staged[produced] = i64(category)
				staged[produced+1] = i64(attempts_since_acceptance)
				produced += 2
				attempts_since_acceptance = 0
				if produced == 2*wanted { break }
			}
		}
		if produced != 2*wanted { return -3 }
		for i in 0 .. produced {
			bits := u64(staged[i])
			for byte in 0 .. 8 { output[8*i+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
