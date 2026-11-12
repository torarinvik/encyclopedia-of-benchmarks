package discrete_rejection_sampling

import "core:c"

MAX_CATEGORIES :: 8
MAX_SAMPLES :: 8
MAX_ATTEMPTS :: 32
MAX_INPUT_VALUES :: 83

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
discrete_rejection_sampling :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_VALUES do return -1
	n64 := input[0]
	samples64 := input[1]
	attempts64 := input[2]
	if n64 < 1 || n64 > MAX_CATEGORIES || samples64 < 1 || samples64 > MAX_SAMPLES ||
		attempts64 < 1 || attempts64 > MAX_ATTEMPTS do return -1
	n := int(n64)
	wanted := int(samples64)
	attempts := int(attempts64)
	if length != c.size_t(3 + 2*n + 2*attempts) do return -1

	target: [MAX_CATEGORIES]u64
	proposal: [MAX_CATEGORIES]u64
	cumulative: [MAX_CATEGORIES]u64
	target_total: u64 = 0
	proposal_total: u64 = 0
	for i := 0; i < n; i += 1 {
		weight := input[3+i]
		q_weight := input[3+n+i]
		if weight < 1 || weight > 20 || q_weight < 1 || q_weight > 20 do return -1
		target[i] = u64(weight)
		proposal[i] = u64(q_weight)
		target_total += target[i]
		proposal_total += proposal[i]
		cumulative[i] = proposal_total
	}

	envelope: u64 = 1
	for i := 0; i < n; i += 1 {
		numerator := target[i] * proposal_total
		denominator := target_total * proposal[i]
		ratio_ceiling := (numerator + denominator - 1) / denominator
		if ratio_ceiling > envelope do envelope = ratio_ceiling
	}

	tape_offset := 3 + 2*n
	for attempt := 0; attempt < attempts; attempt += 1 {
		proposal_draw := input[tape_offset+2*attempt]
		acceptance_draw := input[tape_offset+2*attempt+1]
		if proposal_draw < 0 || u64(proposal_draw) >= proposal_total || acceptance_draw < 0 do return -1
		category := 0
		for category < n && cumulative[category] <= u64(proposal_draw) { category += 1 }
		acceptance_range := target_total * proposal[category] * envelope
		if u64(acceptance_draw) >= acceptance_range do return -1
	}

	output_bytes := 16*wanted
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [2*MAX_SAMPLES]i64
	produced := 0
	attempts_since_acceptance := 0
	for attempt := 0; attempt < attempts; attempt += 1 {
		attempts_since_acceptance += 1
		proposal_draw := u64(input[tape_offset+2*attempt])
		acceptance_draw := u64(input[tape_offset+2*attempt+1])
		category := 0
		for category < n && cumulative[category] <= proposal_draw { category += 1 }
		if acceptance_draw < i64(target[category] * proposal_total) {
			staged[produced] = i64(category)
			staged[produced+1] = i64(attempts_since_acceptance)
			produced += 2
			attempts_since_acceptance = 0
			if produced == 2*wanted do break
		}
	}
	if produced != 2*wanted do return -3
	for i := 0; i < produced; i += 1 { store_i64_le(output, 8*i, staged[i]) }
	return i64(output_bytes)
}
