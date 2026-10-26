package hospitals_residents_rgs

import "core:c"

MAX_R :: 8
MAX_H :: 8
MAX_INPUT :: 154
MAX_OUTPUT :: 64

put64 :: proc(output: [^]u8, position: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[position+byte] = u8(bits&255); bits >>= 8 }
}

@(export)
hospitals_residents_rgs :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_INPUT do return -1
	r64, h64 := input[0], input[1]
	if r64 < 1 || r64 > MAX_R || h64 < 1 || h64 > MAX_H do return -1
	r, h := int(r64), int(h64)
	if length != c.size_t(2+2*h+r+2*r*h) do return -1
	cap_offset := 2
	rlen_offset := cap_offset+h
	rpref_offset := rlen_offset+r
	hlen_offset := rpref_offset+r*h
	hpref_offset := hlen_offset+h
	capacities: [MAX_H]i64
	resident_length: [MAX_R]i64
	resident_pref: [MAX_R*MAX_H]i64
	hospital_length: [MAX_H]i64
	hospital_rank: [MAX_H*MAX_R]i64
	assignment: [MAX_R]i64
	next_choice: [MAX_R]int
	occupancy: [MAX_H]int
	for hospital := 0; hospital < h; hospital += 1 {
		capacities[hospital] = input[cap_offset+hospital]
		hospital_length[hospital] = input[hlen_offset+hospital]
		if capacities[hospital] < 1 || capacities[hospital] > r64 || hospital_length[hospital] < 0 || hospital_length[hospital] > r64 do return -1
		for resident := 0; resident < r; resident += 1 { hospital_rank[hospital*MAX_R+resident] = -1 }
	}
	for resident := 0; resident < r; resident += 1 {
		resident_length[resident] = input[rlen_offset+resident]
		if resident_length[resident] < 0 || resident_length[resident] > h64 do return -1
		seen: [MAX_H]bool
		for slot := 0; slot < h; slot += 1 {
			value := input[rpref_offset+resident*h+slot]
			if slot < int(resident_length[resident]) {
				if value < 0 || value >= h64 || seen[int(value)] do return -1
				seen[int(value)] = true
				resident_pref[resident*MAX_H+slot] = value
			} else {
				if value != -1 do return -1
				resident_pref[resident*MAX_H+slot] = -1
			}
		}
		assignment[resident] = -1
	}
	for hospital := 0; hospital < h; hospital += 1 {
		seen: [MAX_R]bool
		for slot := 0; slot < r; slot += 1 {
			value := input[hpref_offset+hospital*r+slot]
			if slot < int(hospital_length[hospital]) {
				if value < 0 || value >= r64 || seen[int(value)] do return -1
				seen[int(value)] = true
				hospital_rank[hospital*MAX_R+int(value)] = i64(slot)
			} else if value != -1 do return -1
		}
	}
	for resident := 0; resident < r; resident += 1 {
		for hospital := 0; hospital < h; hospital += 1 {
			accepts := false
			for slot := 0; slot < int(resident_length[resident]); slot += 1 {
				if resident_pref[resident*MAX_H+slot] == i64(hospital) { accepts = true }
			}
			if accepts != (hospital_rank[hospital*MAX_R+resident] >= 0) do return -1
		}
	}
	output_bytes := 8*r
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for {
		proposer := r
		for resident := 0; resident < r; resident += 1 {
			if assignment[resident] == -1 && next_choice[resident] < int(resident_length[resident]) { proposer = resident; break }
		}
		if proposer == r do break
		hospital := int(resident_pref[proposer*MAX_H+next_choice[proposer]])
		next_choice[proposer] += 1
		if occupancy[hospital] < int(capacities[hospital]) {
			assignment[proposer] = i64(hospital)
			occupancy[hospital] += 1
		} else {
			worst := r
			for resident := 0; resident < r; resident += 1 {
				if assignment[resident] == i64(hospital) &&
					(worst == r || hospital_rank[hospital*MAX_R+resident] > hospital_rank[hospital*MAX_R+worst]) { worst = resident }
			}
			if worst == r do return -1
			if hospital_rank[hospital*MAX_R+proposer] < hospital_rank[hospital*MAX_R+worst] {
				assignment[worst] = -1
				assignment[proposer] = i64(hospital)
			}
		}
	}
	staged: [MAX_OUTPUT]u8
	for resident := 0; resident < r; resident += 1 { put64(&staged[0], 8*resident, assignment[resident]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
