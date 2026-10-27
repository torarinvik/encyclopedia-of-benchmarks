package yds_speed_scaling

import "core:c"

MAX_JOBS :: 4
MAX_TIME :: 8
MAX_INPUT :: 13
MAX_OUTPUT :: 152

gcd64 :: proc(a0, b0: i64) -> i64 {
	a, b := a0, b0
	for b != 0 { r := a % b; a = b; b = r }
	return a
}

put64 :: proc(output: [^]u8, at: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[at+byte] = u8(bits&255); bits >>= 8 }
}

@(export)
yds_speed_scaling :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	n64 := input[0]
	if n64 < 1 || n64 > MAX_JOBS do return -1
	n := int(n64)
	if length != c.size_t(1+3*n) do return -1
	release: [MAX_JOBS]int
	deadline: [MAX_JOBS]int
	work: [MAX_JOBS]i64
	active: [MAX_JOBS]bool
	for j := 0; j < n; j += 1 {
		r, d, w := input[1+3*j], input[2+3*j], input[3+3*j]
		if r < 0 || r >= d || d > MAX_TIME || w < 1 || w > 8 do return -1
		release[j], deadline[j], work[j], active[j] = int(r), int(d), w, true
	}
	staged: [MAX_OUTPUT/8]i64
	output_values, stages := 3, 0
	energy_num, energy_den := i64(0), i64(1)
	remaining := n
	for remaining > 0 {
		release_seen: [MAX_TIME+1]bool
		deadline_seen: [MAX_TIME+1]bool
		for j := 0; j < n; j += 1 { if active[j] { release_seen[release[j]] = true; deadline_seen[deadline[j]] = true } }
		have_best := false
		best_a, best_b := 0, 1
		best_work, best_duration := i64(0), i64(1)
		for a := 0; a <= MAX_TIME; a += 1 {
			if !release_seen[a] do continue
			for b := a+1; b <= MAX_TIME; b += 1 {
				if !deadline_seen[b] do continue
				total := i64(0)
				for j := 0; j < n; j += 1 { if active[j] && release[j] >= a && deadline[j] <= b { total += work[j] } }
				if total == 0 do continue
				duration := i64(b-a)
				if !have_best || total*best_duration > best_work*duration ||
					(total*best_duration == best_work*duration && (a < best_a || (a == best_a && b < best_b))) {
					have_best, best_a, best_b, best_work, best_duration = true, a, b, total, duration
				}
			}
		}
		if !have_best do return -1
		job_mask: u64 = 0
		for j := 0; j < n; j += 1 { if active[j] && release[j] >= best_a && deadline[j] <= best_b { job_mask |= 1u64 << j } }
		staged[output_values] = i64(best_a); output_values += 1
		staged[output_values] = i64(best_b); output_values += 1
		staged[output_values] = best_work; output_values += 1
		staged[output_values] = i64(job_mask); output_values += 1
		term_num, term_den := best_work*best_work*best_work, best_duration*best_duration
		common := gcd64(energy_den, term_den)
		energy_num = energy_num*(term_den/common) + term_num*(energy_den/common)
		energy_den *= term_den/common
		energy_gcd := gcd64(energy_num, energy_den)
		energy_num /= energy_gcd; energy_den /= energy_gcd
		for j := 0; j < n; j += 1 {
			if !active[j] do continue
			if release[j] >= best_a && deadline[j] <= best_b { active[j] = false; remaining -= 1 }
			else {
				if release[j] > best_a && release[j] < best_b { release[j] = best_a }
				else if release[j] >= best_b { release[j] -= int(best_duration) }
				if deadline[j] > best_a && deadline[j] < best_b { deadline[j] = best_a }
				else if deadline[j] >= best_b { deadline[j] -= int(best_duration) }
			}
		}
		stages += 1
	}
	staged[0], staged[1], staged[2] = i64(stages), energy_num, energy_den
	output_bytes := 8*output_values
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	bytes: [MAX_OUTPUT]u8
	for i := 0; i < output_values; i += 1 { put64(&bytes[0],8*i,staged[i]) }
	for i := 0; i < output_bytes; i += 1 { output[i] = bytes[i] }
	return i64(output_bytes)
}
