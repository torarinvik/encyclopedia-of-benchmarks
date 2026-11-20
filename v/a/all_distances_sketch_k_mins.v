module all_distances_sketch_k_mins

const adm_max_n = 6
const adm_max_assignments = 3
const adm_max_input = 27
const adm_max_words = 73

fn adm_put_i64(mut output &u8, word int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[word * 8 + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'all_distances_sketch_k_mins']
pub fn all_distances_sketch_k_mins(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > adm_max_input { return -1 }
	n0 := unsafe { input[0] }
	assignments0 := unsafe { input[1] }
	if n0 < 1 || n0 > adm_max_n || assignments0 < 1 || assignments0 > adm_max_assignments { return -1 }
	n := int(n0)
	assignments := int(assignments0)
	if length != usize(2 + n + assignments * n) { return -1 }

	mut distances := [adm_max_n]i64{}
	for item in 0 .. n {
		distance := unsafe { input[2 + item] }
		if distance < 0 || distance > 1000000 || (item > 0 && distances[item - 1] >= distance) { return -1 }
		distances[item] = distance
	}
	mut ranks := [adm_max_assignments * adm_max_n]i64{}
	for assignment in 0 .. assignments {
		mut seen := [adm_max_n]bool{}
		for item in 0 .. n {
			rank := unsafe { input[2 + n + assignment * n + item] }
			if rank < 0 || rank >= n0 || seen[int(rank)] { return -1 }
			seen[int(rank)] = true
			ranks[assignment * adm_max_n + item] = rank
		}
	}

	mut staged := [adm_max_words]i64{}
	mut count := 0
	for assignment in 0 .. assignments {
		mut best_rank := n0
		for item in 0 .. n {
			rank := ranks[assignment * adm_max_n + item]
			if rank < best_rank {
				staged[1 + 4 * count] = i64(assignment)
				staged[2 + 4 * count] = i64(item)
				staged[3 + 4 * count] = rank
				staged[4 + 4 * count] = distances[item]
				count++
				best_rank = rank
			}
		}
	}
	staged[0] = i64(count)
	words := 1 + 4 * count
	bytes := usize(8 * words)
	if unsafe { output == nil } || capacity < bytes { return -2 }
	for word in 0 .. words { adm_put_i64(mut &output[0], word, staged[word]) }
	return i64(bytes)
}
