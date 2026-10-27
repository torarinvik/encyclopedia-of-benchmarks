module kiraly_max_smt_i_approx

const max_m = 6
const max_w = 6
const max_input = 74
const max_output = 48
const max_steps = 121

fn put64(output &u8, position int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[position+byte] = u8((bits >> (8*byte)) & 255) }
	}
}

@[export: 'kiraly_max_smt_i_approx']
pub fn kiraly_max_smt_i_approx(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		m64, w64 := input[0], input[1]
		if m64 < 1 || m64 > max_m || w64 < 1 || w64 > max_w { return -1 }
		m, w := int(m64), int(w64)
		if length != usize(2+2*m*w) { return -1 }
		mut men_rank := [max_m*max_w]i64{init: 0}
		mut women_rank := [max_w*max_m]i64{init: 0}
		mut live := [max_m*max_w]bool{init: false}
		mut assignment := [max_m]i64{init: -1}
		mut woman_partner := [max_w]i64{init: -1}
		mut status := [max_m]int{init: 0} // lad, bachelor, old bachelor
		for man in 0 .. m {
			for woman in 0 .. w {
				rank := input[2+man*w+woman]
				if rank < -1 || rank >= max_w { return -1 }
				men_rank[man*max_w+woman] = rank
			}
		}
		for woman in 0 .. w {
			for man in 0 .. m {
				rank := input[2+m*w+woman*m+man]
				if rank < -1 || rank >= max_m { return -1 }
				women_rank[woman*max_m+man] = rank
			}
		}
		for man in 0 .. m {
			for woman in 0 .. w {
				ma := men_rank[man*max_w+woman] >= 0
				wa := women_rank[woman*max_m+man] >= 0
				if ma != wa { return -1 }
				live[man*max_w+woman] = ma
			}
		}
		output_bytes := 8*m
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut steps := 0
		for {
			steps++
			if steps > max_steps { return -1 }
			mut man := m
			for x in 0 .. m { if status[x] != 2 && assignment[x] == -1 { man = x; break } }
			if man == m { break }
			mut woman := w
			for x in 0 .. w {
				if live[man*max_w+x] {
					mut better := woman == w
					if !better {
						rn, ro := men_rank[man*max_w+x], men_rank[man*max_w+woman]
						if rn < ro { better = true }
						else if rn == ro {
							nm, om := woman_partner[x] == -1, woman_partner[woman] == -1
							if nm != om { better = nm } else { better = x < woman }
						}
					}
					if better { woman = x }
				}
			}
			if woman == w {
				if status[man] == 0 {
					status[man] = 1
					for x in 0 .. w { live[man*max_w+x] = men_rank[man*max_w+x] >= 0 }
				} else { status[man] = 2 }
				continue
			}
			incumbent64 := woman_partner[woman]
			if incumbent64 < 0 {
				assignment[man], woman_partner[woman] = i64(woman), i64(man)
				continue
			}
			incumbent := int(incumbent64)
			mut old_uncertain := false
			if status[incumbent] == 0 && assignment[incumbent] >= 0 {
				fiance := int(assignment[incumbent])
				for x in 0 .. w {
					if live[incumbent*max_w+x] && x != fiance {
						rn, ro := men_rank[incumbent*max_w+x], men_rank[incumbent*max_w+fiance]
						mut preferred := rn < ro
						if rn == ro {
							nm, fm := woman_partner[x] == -1, woman_partner[fiance] == -1
							if nm != fm { preferred = nm }
						}
						if preferred { old_uncertain = true; break }
					}
				}
			}
			mut accept := old_uncertain
			if !accept {
				rn, ro := women_rank[woman*max_m+man], women_rank[woman*max_m+incumbent]
				if rn < ro { accept = true }
				else if rn == ro {
					if status[man] != status[incumbent] { accept = status[man] > status[incumbent] }
					else { accept = man < incumbent }
				}
			}
			if accept {
				assignment[incumbent], woman_partner[woman] = -1, -1
				if !old_uncertain { live[incumbent*max_w+woman] = false }
				assignment[man], woman_partner[woman] = i64(woman), i64(man)
			} else { live[man*max_w+woman] = false }
		}
		mut staged := [max_output]u8{init: 0}
		for man in 0 .. m { put64(&staged[0], 8*man, assignment[man]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
