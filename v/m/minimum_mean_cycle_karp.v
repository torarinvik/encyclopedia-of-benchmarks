module minimum_mean_cycle_karp

const max_n = 8
const max_m = 16
const max_input = 51

fn store_i64_le(mut output []u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn ratio_less(a_num i64, a_den i64, b_num i64, b_den i64) bool {
	return a_num * b_den < b_num * a_den
}

fn gcd_positive(a_value i64, b_value i64) i64 {
	mut a := a_value
	mut b := b_value
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

fn all_reachable(n int, adjacent [64]bool, reverse bool) bool {
	mut seen := [8]bool{}
	mut queue := [8]int{}
	mut head := 0
	mut tail := 1
	seen[0] = true
	for head < tail {
		u := queue[head]
		head++
		for v in 0 .. n {
			slot := if reverse { v * 8 + u } else { u * 8 + v }
			if adjacent[slot] && !seen[v] {
				seen[v] = true
				queue[tail] = v
				tail++
			}
		}
	}
	for v in 0 .. n { if !seen[v] { return false } }
	return true
}

@[export: 'minimum_mean_cycle_karp']
pub fn minimum_mean_cycle_karp(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || length > max_input || unsafe { input == nil } { return -1 }
	n_value := input[0]
	m_value := input[1]
	if n_value < 1 || n_value > max_n || m_value < 1 || m_value > max_m { return -1 }
	n := int(n_value)
	m := int(m_value)
	if m > n * n || int(length) != 2 + 3 * m { return -1 }

	mut edge_from := [16]int{}
	mut edge_to := [16]int{}
	mut edge_weight := [16]i64{}
	mut adjacent := [64]bool{}
	unsafe {
		for edge in 0 .. m {
			u_value := input[2 + 3 * edge]
			v_value := input[3 + 3 * edge]
			weight := input[4 + 3 * edge]
			if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || weight < -1000 || weight > 1000 { return -1 }
			u := int(u_value)
			v := int(v_value)
			slot := u * 8 + v
			if adjacent[slot] { return -1 }
			adjacent[slot] = true
			edge_from[edge] = u
			edge_to[edge] = v
			edge_weight[edge] = weight
		}
	}
	if !all_reachable(n, adjacent, false) || !all_reachable(n, adjacent, true) { return -1 }
	if output_capacity < 16 || unsafe { output == nil } { return -2 }

	mut cost := [72]i64{}
	mut reachable := [72]bool{}
	reachable[0] = true
	for k in 1 .. n + 1 {
		for edge in 0 .. m {
			u := edge_from[edge]
			v := edge_to[edge]
			previous := (k - 1) * 8 + u
			current := k * 8 + v
			if !reachable[previous] { continue }
			candidate := cost[previous] + edge_weight[edge]
			if !reachable[current] || candidate < cost[current] {
				reachable[current] = true
				cost[current] = candidate
			}
		}
	}

	mut have_answer := false
	mut answer_num := i64(0)
	mut answer_den := i64(1)
	for v in 0 .. n {
		if !reachable[n * 8 + v] { continue }
		mut have_local := false
		mut local_num := i64(0)
		mut local_den := i64(1)
		for k in 0 .. n {
			slot := k * 8 + v
			if !reachable[slot] { continue }
			numerator := cost[n * 8 + v] - cost[slot]
			denominator := i64(n - k)
			if !have_local || ratio_less(local_num, local_den, numerator, denominator) {
				local_num = numerator
				local_den = denominator
				have_local = true
			}
		}
		if have_local && (!have_answer || ratio_less(local_num, local_den, answer_num, answer_den)) {
			answer_num = local_num
			answer_den = local_den
			have_answer = true
		}
	}
	if !have_answer { return -1 }
	abs_num := if answer_num < 0 { -answer_num } else { answer_num }
	divisor := gcd_positive(abs_num, answer_den)
	answer_num /= divisor
	answer_den /= divisor
	mut staged := [16]u8{}
	store_i64_le(mut staged[..], 0, answer_num)
	store_i64_le(mut staged[..], 8, answer_den)
	unsafe {
		for byte in 0 .. 16 { output[byte] = staged[byte] }
	}
	return 16
}
