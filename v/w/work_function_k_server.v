// Clean-room finite-metric work-function algorithm profile.
module work_function_k_server

const max_p = 6
const max_k = 3
const max_r = 8
const max_configs = 20
const max_input = 50

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

fn sort_config(mut values [max_k]i64, k int) {
	for i in 0 .. k { for j in i + 1 .. k { if values[j] < values[i] { values[i], values[j] = values[j], values[i] } } }
}

fn find_config(configs [max_configs][max_k]i64, count int, values [max_k]i64, k int) int {
	for i in 0 .. count {
		mut same := true
		for j in 0 .. k { if configs[i][j] != values[j] { same = false } }
		if same { return i }
	}
	return count
}

fn config_distance(a [max_k]i64, b [max_k]i64, k int, metric [max_p][max_p]i64) i64 {
	if k == 1 { return metric[int(a[0])][int(b[0])] }
	if k == 2 {
		first := metric[int(a[0])][int(b[0])] + metric[int(a[1])][int(b[1])]
		second := metric[int(a[0])][int(b[1])] + metric[int(a[1])][int(b[0])]
		return if first < second { first } else { second }
	}
	perms := [6][3]int{{0,1,2},{0,2,1},{1,0,2},{1,2,0},{2,0,1},{2,1,0}}
	mut best := i64(0x7fffffffffffffff)
	for perm in perms {
		value := metric[int(a[0])][int(b[perm[0]])] + metric[int(a[1])][int(b[perm[1]])] + metric[int(a[2])][int(b[perm[2]])]
		if value < best { best = value }
	}
	return best
}

@[export: 'work_function_k_server']
pub fn work_function_k_server(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		p64, k64, n64 := input[0], input[1], input[2]
		if p64 < 2 || p64 > max_p || k64 < 1 || k64 > max_k || k64 > p64 || n64 < 0 || n64 > max_r { return -1 }
		p, k, n := int(p64), int(k64), int(n64)
		initial_at := 3 + p * p
		requests_at := initial_at + k
		if length != usize(requests_at + n) { return -1 }
		mut metric := [max_p][max_p]i64{}
		for i in 0 .. p { for j in 0 .. p {
			value := input[3 + i*p + j]
			if value < 0 || value > 1000 || (i == j && value != 0) || (i != j && value == 0) { return -1 }
			metric[i][j] = value
		} }
		for i in 0 .. p { for j in 0 .. p {
			if metric[i][j] != metric[j][i] { return -1 }
			for z in 0 .. p { if metric[i][j] > metric[i][z] + metric[z][j] { return -1 } }
		} }
		mut initial := [max_k]i64{}
		for i in 0 .. k { initial[i] = input[initial_at+i]; if initial[i] < 0 || initial[i] >= p64 { return -1 }; for j in 0 .. i { if initial[j] == initial[i] { return -1 } } }
		sort_config(mut initial, k)
		mut requests := [max_r]i64{}
		for t in 0 .. n { requests[t] = input[requests_at+t]; if requests[t] < 0 || requests[t] >= p64 { return -1 } }
		output_bytes := 8 * (2 + n*k)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut configs := [max_configs][max_k]i64{}
		mut count := 0
		for a in 0 .. p {
			if k == 1 { configs[count][0] = i64(a); count++; continue }
			for b in a+1 .. p {
				if k == 2 { configs[count][0] = i64(a); configs[count][1] = i64(b); count++; continue }
				for c in b+1 .. p { configs[count] = [i64(a), i64(b), i64(c)]; count++ }
			}
		}
		mut work := [max_configs]i64{}
		mut next_work := [max_configs]i64{}
		for x in 0 .. count { work[x] = config_distance(initial, configs[x], k, metric) }
		mut staged := [2 + max_r*max_k]i64{}
		staged[0] = i64(n); staged[1] = i64(k)
		mut current := initial
		for t in 0 .. n {
			r := requests[t]
			for x in 0 .. count {
				next_work[x] = i64(0x7fffffffffffffff)
				for y in 0 .. count {
					mut contains := false
					for j in 0 .. k { if configs[y][j] == r { contains = true } }
					if contains { value := work[y] + config_distance(configs[y], configs[x], k, metric); if value < next_work[x] { next_work[x] = value } }
				}
			}
			mut chosen := current
			mut already_served := false
			for j in 0 .. k { if current[j] == r { already_served = true } }
			if !already_served {
				mut best := i64(0x7fffffffffffffff)
				mut best_slot := 0
				for slot in 0 .. k {
					mut candidate := current
					candidate[slot] = r
					sort_config(mut candidate, k)
					index := find_config(configs, count, candidate, k)
					score := work[index] + metric[int(current[slot])][int(r)]
					if score < best || (score == best && slot < best_slot) { best = score; best_slot = slot; chosen = candidate }
				}
			}
			for j in 0 .. k { staged[2+t*k+j] = chosen[j]; current[j] = chosen[j] }
			for x in 0 .. count { work[x] = next_work[x] }
		}
		for i in 0 .. 2+n*k { store_i64_le(mut output, 8*i, staged[i]) }
		return i64(output_bytes)
	}
}
