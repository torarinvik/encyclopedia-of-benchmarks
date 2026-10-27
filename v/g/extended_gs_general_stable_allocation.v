module extended_gs_general_stable_allocation

const max_input = 19
const max_output_bytes = 104
const inf = i64(255)

fn utility(first i64, second i64, count i64) i64 {
	if count == 0 { return 0 }
	if count == 1 { return first }
	return first + second
}

fn choose_men(men int, women int, quota i64, edges int, mf [4]i64, ms [4]i64,
	lower [4]i64, upper [4]i64) [4]i64 {
	mut answer := [4]i64{}
	mut best_value := i64(-1)
	mut codes := 1
	for _ in 0 .. edges { codes *= 3 }
	for code in 0 .. codes {
		mut candidate := [4]i64{}
		mut remainder := code
		for edge in 0 .. edges {
			index := edges - 1 - edge
			candidate[index] = i64(remainder % 3)
			remainder /= 3
		}
		mut feasible := true
		for edge in 0 .. edges { if candidate[edge] < lower[edge] || candidate[edge] > upper[edge] { feasible = false } }
		for man in 0 .. men {
			mut total := i64(0)
			for woman in 0 .. women { total += candidate[man * women + woman] }
			if total > quota { feasible = false }
		}
		if !feasible { continue }
		mut value := i64(0)
		for edge in 0 .. edges { value += utility(mf[edge], ms[edge], candidate[edge]) }
		if value > best_value {
			best_value = value
			for edge in 0 .. edges { answer[edge] = candidate[edge] }
		}
	}
	return answer
}

fn choose_women(men int, women int, quota i64, edges int, wf [4]i64, ws [4]i64,
	upper [4]i64) [4]i64 {
	mut answer := [4]i64{}
	mut best_value := i64(-1)
	mut codes := 1
	for _ in 0 .. edges { codes *= 3 }
	for code in 0 .. codes {
		mut candidate := [4]i64{}
		mut remainder := code
		for edge in 0 .. edges {
			index := edges - 1 - edge
			candidate[index] = i64(remainder % 3)
			remainder /= 3
		}
		mut feasible := true
		for edge in 0 .. edges { if candidate[edge] > upper[edge] { feasible = false } }
		for woman in 0 .. women {
			mut total := i64(0)
			for man in 0 .. men { total += candidate[man * women + woman] }
			if total > quota { feasible = false }
		}
		if !feasible { continue }
		mut value := i64(0)
		for edge in 0 .. edges { value += utility(wf[edge], ws[edge], candidate[edge]) }
		if value > best_value {
			best_value = value
			for edge in 0 .. edges { answer[edge] = candidate[edge] }
		}
	}
	return answer
}

fn put_i64(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'extended_gs_general_stable_allocation']
pub fn extended_gs_general_stable_allocation(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == unsafe { nil } || length < 3 || length > max_input { return -1 }
	men_value := unsafe { input[0] }
	women_value := unsafe { input[1] }
	quota := unsafe { input[2] }
	if men_value < 1 || men_value > 2 || women_value < 1 || women_value > 2 || quota < 1 || quota > 2 { return -1 }
	men, women := int(men_value), int(women_value)
	edges := men * women
	if int(length) != 3 + 4 * edges { return -1 }
	mut mf := [4]i64{}
	mut ms := [4]i64{}
	mut wf := [4]i64{}
	mut ws := [4]i64{}
	for edge in 0 .. edges {
		mf[edge] = unsafe { input[3 + 4 * edge] }; ms[edge] = unsafe { input[4 + 4 * edge] }
		wf[edge] = unsafe { input[5 + 4 * edge] }; ws[edge] = unsafe { input[6 + 4 * edge] }
		if mf[edge] < 0 || mf[edge] > 8 || ms[edge] < 0 || ms[edge] > mf[edge]
			|| wf[edge] < 0 || wf[edge] > 8 || ws[edge] < 0 || ws[edge] > wf[edge] { return -1 }
	}
	mut x_w := [4]i64{}
	mut z_m := [4]i64{}
	mut z_w := [4]i64{}
	mut x_m := [4]i64{}
	mut next_w := [4]i64{}
	for edge in 0 .. edges { z_m[edge] = inf }
	mut converged := false
	for _ in 0 .. 3 * edges + 2 {
		x_m = choose_men(men, women, quota, edges, mf, ms, x_w, z_m)
		next_w = choose_women(men, women, quota, edges, wf, ws, x_m)
		converged = true
		for edge in 0 .. edges { if x_m[edge] != next_w[edge] { converged = false } }
		if converged { break }
		for edge in 0 .. edges {
			if x_m[edge] > next_w[edge] { z_m[edge] = next_w[edge]; z_w[edge] = inf }
			x_w[edge] = next_w[edge]
		}
	}
	if !converged { return -1 }
	output_values := 1 + 3 * edges
	output_bytes := 8 * output_values
	if output == unsafe { nil } || capacity < usize(output_bytes) { return -2 }
	mut staged := [max_output_bytes]u8{}
	put_i64(mut staged[..], 0, i64(edges))
	for edge in 0 .. edges {
		put_i64(mut staged[..], 8 * (1 + edge), x_m[edge])
		put_i64(mut staged[..], 8 * (1 + edges + edge), z_m[edge])
		put_i64(mut staged[..], 8 * (1 + 2 * edges + edge), if z_w[edge] > x_m[edge] { z_w[edge] } else { x_m[edge] })
	}
	for byte in 0 .. output_bytes { unsafe { output[byte] = staged[byte] } }
	return i64(output_bytes)
}
