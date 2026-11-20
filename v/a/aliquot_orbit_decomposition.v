module aliquot_orbit_decomposition

const max_terms = 4097
const max_input = 3
const max_seed = i64(100000)
const max_value = i64(100000)
const max_transitions = i64(4096)

fn aliquot_sum(value i64) i64 {
	if value == 1 { return 0 }
	mut total := i64(1)
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 {
			total += divisor
			partner := value / divisor
			if partner != divisor { total += partner }
		}
		divisor++
	}
	return total
}

fn store_i64(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'aliquot_orbit_decomposition']
pub fn aliquot_orbit_decomposition(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input { return -1 }
	unsafe {
		if length != 2 || input[0] < 1 || input[0] > max_seed || input[1] < 1 || input[1] > max_transitions { return -1 }
		mut keys := [max_terms]i64{init: 0}
		mut first_indices := [max_terms]i64{init: 0}
		mut key_count := 0
		mut words := [3]i64{init: 0}
		mut current := input[0]
		mut transitions := i64(0)
		mut positive_count := i64(0)
		for {
			if current == 0 {
				words[0] = 0
				words[1] = positive_count
				words[2] = 0
				break
			}
			mut low := 0
			mut high := key_count
			for low < high {
				middle := low + (high - low) / 2
				if keys[middle] < current { low = middle + 1 } else { high = middle }
			}
			if low < key_count && keys[low] == current {
				words[0] = 1
				words[1] = first_indices[low]
				words[2] = transitions - first_indices[low]
				break
			}
			mut cursor := key_count
			for cursor > low {
				keys[cursor] = keys[cursor - 1]
				first_indices[cursor] = first_indices[cursor - 1]
				cursor--
			}
			keys[low] = current
			first_indices[low] = transitions
			key_count++
			positive_count++
			if transitions >= input[1] {
				words[0] = -3
				words[1] = transitions
				words[2] = current
				break
			}
			next_value := aliquot_sum(current)
			transitions++
			if next_value > max_value {
				words[0] = -2
				words[1] = transitions
				words[2] = next_value
				break
			}
			current = next_value
		}
		if unsafe { output == nil } || capacity < 24 { return -2 }
		mut bytes := [24]u8{init: 0}
		for word in 0 .. 3 { store_i64(mut bytes[0], word * 8, words[word]) }
		for byte in 0 .. 24 { output[byte] = bytes[byte] }
		return 24
	}
}
