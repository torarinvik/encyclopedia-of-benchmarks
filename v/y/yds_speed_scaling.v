module yds_speed_scaling

const max_jobs = 4
const max_time = 8
const max_input = 13
const max_output = 152

fn gcd64(a0 i64, b0 i64) i64 {
	mut a, b := a0, b0
	for b != 0 { r := a % b; a = b; b = r }
	return a
}

fn put64(output &u8, at int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[at + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'yds_speed_scaling']
pub fn yds_speed_scaling(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		n64 := input[0]
		if n64 < 1 || n64 > max_jobs { return -1 }
		n := int(n64)
		if length != usize(1 + 3 * n) { return -1 }
		mut release := [max_jobs]int{init: 0}
		mut deadline := [max_jobs]int{init: 0}
		mut work := [max_jobs]i64{init: 0}
		mut active := [max_jobs]bool{init: false}
		for j in 0 .. n {
			r, d, w := input[1 + 3*j], input[2 + 3*j], input[3 + 3*j]
			if r < 0 || r >= d || d > max_time || w < 1 || w > 8 { return -1 }
			release[j], deadline[j], work[j], active[j] = int(r), int(d), w, true
		}
		mut staged := [max_output / 8]i64{init: 0}
		mut output_values, stages := 3, 0
		mut energy_num, energy_den := i64(0), i64(1)
		mut remaining := n
		for remaining > 0 {
			mut release_seen := [max_time + 1]bool{init: false}
			mut deadline_seen := [max_time + 1]bool{init: false}
			for j in 0 .. n { if active[j] { release_seen[release[j]] = true; deadline_seen[deadline[j]] = true } }
			mut have_best := false
			mut best_a, best_b := 0, 1
			mut best_work, best_duration := i64(0), i64(1)
			for a in 0 .. max_time + 1 {
				if !release_seen[a] { continue }
				for b in a + 1 .. max_time + 1 {
					if !deadline_seen[b] { continue }
					mut total := i64(0)
					for j in 0 .. n { if active[j] && release[j] >= a && deadline[j] <= b { total += work[j] } }
					if total == 0 { continue }
					duration := i64(b - a)
					if !have_best || total * best_duration > best_work * duration ||
						(total * best_duration == best_work * duration && (a < best_a || (a == best_a && b < best_b))) {
						have_best, best_a, best_b, best_work, best_duration = true, a, b, total, duration
					}
				}
			}
			if !have_best { return -1 }
			mut job_mask := i64(0)
			for j in 0 .. n { if active[j] && release[j] >= best_a && deadline[j] <= best_b { job_mask |= i64(1) << j } }
			staged[output_values] = i64(best_a); output_values++
			staged[output_values] = i64(best_b); output_values++
			staged[output_values] = best_work; output_values++
			staged[output_values] = job_mask; output_values++
			term_num, term_den := best_work * best_work * best_work, best_duration * best_duration
			common := gcd64(energy_den, term_den)
			energy_num = energy_num * (term_den / common) + term_num * (energy_den / common)
			energy_den *= term_den / common
			energy_gcd := gcd64(energy_num, energy_den)
			energy_num /= energy_gcd
			energy_den /= energy_gcd
			for j in 0 .. n {
				if !active[j] { continue }
				if release[j] >= best_a && deadline[j] <= best_b { active[j] = false; remaining-- }
				else {
					if release[j] > best_a && release[j] < best_b { release[j] = best_a }
					else if release[j] >= best_b { release[j] -= int(best_duration) }
					if deadline[j] > best_a && deadline[j] < best_b { deadline[j] = best_a }
					else if deadline[j] >= best_b { deadline[j] -= int(best_duration) }
				}
			}
			stages++
		}
		staged[0], staged[1], staged[2] = i64(stages), energy_num, energy_den
		output_bytes := 8 * output_values
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut bytes := [max_output]u8{init: 0}
		for i in 0 .. output_values { put64(&bytes[0], 8 * i, staged[i]) }
		for i in 0 .. output_bytes { output[i] = bytes[i] }
		return i64(output_bytes)
	}
}
