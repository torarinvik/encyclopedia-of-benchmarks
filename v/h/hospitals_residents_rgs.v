module hospitals_residents_rgs

const max_r = 8
const max_h = 8
const max_input = 154
const max_output = 64

fn put64(output &u8, position int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[position+byte] = u8((bits >> (8*byte)) & 255) }
	}
}

@[export: 'hospitals_residents_rgs']
pub fn hospitals_residents_rgs(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_input { return -1 }
		r64, h64 := input[0], input[1]
		if r64 < 1 || r64 > max_r || h64 < 1 || h64 > max_h { return -1 }
		r, h := int(r64), int(h64)
		if length != usize(2+2*h+r+2*r*h) { return -1 }
		cap_offset := 2
		rlen_offset := cap_offset+h
		rpref_offset := rlen_offset+r
		hlen_offset := rpref_offset+r*h
		hpref_offset := hlen_offset+h
		mut capacities := [max_h]i64{init: 0}
		mut resident_length := [max_r]i64{init: 0}
		mut resident_pref := [max_r*max_h]i64{init: -1}
		mut hospital_length := [max_h]i64{init: 0}
		mut hospital_rank := [max_h*max_r]i64{init: -1}
		mut assignment := [max_r]i64{init: -1}
		mut next_choice := [max_r]int{init: 0}
		mut occupancy := [max_h]int{init: 0}
		for hospital in 0 .. h {
			capacities[hospital] = input[cap_offset+hospital]
			hospital_length[hospital] = input[hlen_offset+hospital]
			if capacities[hospital] < 1 || capacities[hospital] > r64 || hospital_length[hospital] < 0 || hospital_length[hospital] > r64 { return -1 }
		}
		for resident in 0 .. r {
			resident_length[resident] = input[rlen_offset+resident]
			if resident_length[resident] < 0 || resident_length[resident] > h64 { return -1 }
			mut seen := [max_h]bool{init: false}
			for slot in 0 .. h {
				value := input[rpref_offset+resident*h+slot]
				if slot < int(resident_length[resident]) {
					if value < 0 || value >= h64 || seen[int(value)] { return -1 }
					seen[int(value)] = true
					resident_pref[resident*max_h+slot] = value
				} else if value != -1 { return -1 }
			}
		}
		for hospital in 0 .. h {
			mut seen := [max_r]bool{init: false}
			for slot in 0 .. r {
				value := input[hpref_offset+hospital*r+slot]
				if slot < int(hospital_length[hospital]) {
					if value < 0 || value >= r64 || seen[int(value)] { return -1 }
					seen[int(value)] = true
					hospital_rank[hospital*max_r+int(value)] = i64(slot)
				} else if value != -1 { return -1 }
			}
		}
		for resident in 0 .. r {
			for hospital in 0 .. h {
				mut accepts := false
				for slot in 0 .. int(resident_length[resident]) {
					if resident_pref[resident*max_h+slot] == i64(hospital) { accepts = true }
				}
				if accepts != (hospital_rank[hospital*max_r+resident] >= 0) { return -1 }
			}
		}
		output_bytes := 8*r
		if output == nil || capacity < output_bytes { return -2 }
		for {
			mut proposer := r
			for resident in 0 .. r {
				if assignment[resident] == -1 && next_choice[resident] < int(resident_length[resident]) { proposer = resident; break }
			}
			if proposer == r { break }
			hospital := int(resident_pref[proposer*max_h+next_choice[proposer]])
			next_choice[proposer]++
			if occupancy[hospital] < int(capacities[hospital]) {
				assignment[proposer] = i64(hospital)
				occupancy[hospital]++
			} else {
				mut worst := r
				for resident in 0 .. r {
					if assignment[resident] == i64(hospital) && (worst == r || hospital_rank[hospital*max_r+resident] > hospital_rank[hospital*max_r+worst]) { worst = resident }
				}
				if worst == r { return -1 }
				if hospital_rank[hospital*max_r+proposer] < hospital_rank[hospital*max_r+worst] {
					assignment[worst] = -1
					assignment[proposer] = i64(hospital)
				}
			}
		}
		mut staged := [max_output]u8{init: 0}
		for resident in 0 .. r {
			bits := u64(assignment[resident])
			for byte in 0 .. 8 { staged[8*resident+byte] = u8((bits >> (8*byte)) & 255) }
		}
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
