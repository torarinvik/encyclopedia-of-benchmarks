module huffman_weighted_cost

const max_symbols = 26
const max_total_frequency = i64(2_147_483_647)

fn store_i64_le(mut output &u8, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 {
			output[byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'huffman_weighted_cost']
pub fn huffman_weighted_cost(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 1 || length > 53 || unsafe { values == nil } { return -1 }
	unsafe {
		raw_count := values[0]
		if raw_count < 2 || raw_count > max_symbols || length != usize(1 + 2 * raw_count) { return -1 }
		count := int(raw_count)
		mut seen := [max_symbols]bool{}
		mut active := [max_symbols]bool{}
		mut weights := [max_symbols]i64{}
		mut total := i64(0)
		for index in 0 .. count {
			symbol := values[1 + 2 * index]
			frequency := values[2 + 2 * index]
			if symbol < 97 || symbol > 122 || frequency < 1 || frequency > max_total_frequency { return -1 }
			letter := int(symbol - 97)
			if seen[letter] || total > max_total_frequency - frequency { return -1 }
			seen[letter] = true
			active[index] = true
			weights[index] = frequency
			total += frequency
		}

		mut remaining := count
		mut cost := i64(0)
		for remaining > 1 {
			mut first := -1
			mut second := -1
			for index in 0 .. count {
				if !active[index] { continue }
				if first < 0 || weights[index] < weights[first] {
					second = first
					first = index
				} else if second < 0 || weights[index] < weights[second] {
					second = index
				}
			}
			weights[first] += weights[second]
			active[second] = false
			cost += weights[first]
			remaining--
		}
		if output == nil || output_capacity < 8 { return -2 }
		store_i64_le(mut output, cost)
		return cost
	}
}
