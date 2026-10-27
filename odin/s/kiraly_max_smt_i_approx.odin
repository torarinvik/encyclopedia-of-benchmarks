package kiraly_max_smt_i_approx

import "core:c"

MAX_M :: 6
MAX_W :: 6
MAX_INPUT :: 74
MAX_OUTPUT :: 48
MAX_STEPS :: 121

put64 :: proc(output: [^]u8, position: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[position+byte] = u8(bits&255); bits >>= 8 }
}

man_prefers :: proc(man, a, b: int, rank: [MAX_M*MAX_W]i64, woman_partner: [MAX_W]i64) -> bool {
	ra, rb := rank[man*MAX_W+a], rank[man*MAX_W+b]
	if ra != rb do return ra < rb
	a_maiden, b_maiden := woman_partner[a] == -1, woman_partner[b] == -1
	if a_maiden != b_maiden do return a_maiden
	return a < b
}

uncertain :: proc(man, w: int, rank: [MAX_M*MAX_W]i64, live: [MAX_M*MAX_W]bool,
	assignment: [MAX_M]i64, woman_partner: [MAX_W]i64, status: [MAX_M]i64) -> bool {
	if status[man] != 0 || assignment[man] < 0 do return false
	fiance := int(assignment[man])
	for woman := 0; woman < w; woman += 1 {
		if live[man*MAX_W+woman] && woman != fiance &&
			(rank[man*MAX_W+woman] < rank[man*MAX_W+fiance] ||
			(rank[man*MAX_W+woman] == rank[man*MAX_W+fiance] && woman_partner[woman] == -1 && woman_partner[fiance] != -1)) do return true
	}
	return false
}

woman_prefers :: proc(woman, candidate, incumbent: int, incumbent_uncertain: bool,
	rank: [MAX_W*MAX_M]i64, status: [MAX_M]i64) -> bool {
	if incumbent_uncertain do return true
	rc, ri := rank[woman*MAX_M+candidate], rank[woman*MAX_M+incumbent]
	if rc != ri do return rc < ri
	if status[candidate] != status[incumbent] do return status[candidate] > status[incumbent]
	return candidate < incumbent
}

@(export)
kiraly_max_smt_i_approx :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	m64, w64 := input[0], input[1]
	if m64 < 1 || m64 > MAX_M || w64 < 1 || w64 > MAX_W do return -1
	m, w := int(m64), int(w64)
	if length != c.size_t(2+2*m*w) do return -1
	men_rank: [MAX_M*MAX_W]i64
	women_rank: [MAX_W*MAX_M]i64
	live: [MAX_M*MAX_W]bool
	assignment: [MAX_M]i64
	woman_partner: [MAX_W]i64
	status: [MAX_M]i64 // lad, bachelor, old bachelor
	for man := 0; man < m; man += 1 {
		assignment[man] = -1
		for woman := 0; woman < w; woman += 1 {
			rank := input[2+man*w+woman]
			if rank < -1 || rank >= MAX_W do return -1
			men_rank[man*MAX_W+woman] = rank
		}
	}
	for woman := 0; woman < w; woman += 1 {
		woman_partner[woman] = -1
		for man := 0; man < m; man += 1 {
			rank := input[2+m*w+woman*m+man]
			if rank < -1 || rank >= MAX_M do return -1
			women_rank[woman*MAX_M+man] = rank
		}
	}
	for man := 0; man < m; man += 1 {
		for woman := 0; woman < w; woman += 1 {
			ma, wa := men_rank[man*MAX_W+woman] >= 0, women_rank[woman*MAX_M+man] >= 0
			if ma != wa do return -1
			live[man*MAX_W+woman] = ma
		}
	}
	output_bytes := 8*m
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	steps := 0
	for {
		steps += 1
		if steps > MAX_STEPS do return -1
		man := m
		for x := 0; x < m; x += 1 { if status[x] != 2 && assignment[x] == -1 { man = x; break } }
		if man == m do break
		woman := w
		for x := 0; x < w; x += 1 {
			if live[man*MAX_W+x] && (woman == w || man_prefers(man, x, woman, men_rank, woman_partner)) { woman = x }
		}
		if woman == w {
			if status[man] == 0 {
				status[man] = 1
				for x := 0; x < w; x += 1 { live[man*MAX_W+x] = men_rank[man*MAX_W+x] >= 0 }
			} else { status[man] = 2 }
			continue
		}
		incumbent64 := woman_partner[woman]
		if incumbent64 < 0 {
			assignment[man], woman_partner[woman] = i64(woman), i64(man)
			continue
		}
		incumbent := int(incumbent64)
		old_uncertain := uncertain(incumbent, w, men_rank, live, assignment, woman_partner, status)
		if woman_prefers(woman, man, incumbent, old_uncertain, women_rank, status) {
			assignment[incumbent], woman_partner[woman] = -1, -1
			if !old_uncertain { live[incumbent*MAX_W+woman] = false }
			assignment[man], woman_partner[woman] = i64(woman), i64(man)
		} else { live[man*MAX_W+woman] = false }
	}
	staged: [MAX_OUTPUT]u8
	for man := 0; man < m; man += 1 { put64(&staged[0], 8*man, assignment[man]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
