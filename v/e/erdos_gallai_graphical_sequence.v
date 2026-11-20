module erdos_gallai_graphical_sequence

const max_vertices = 256
const max_parseable_length = 258

@[export: 'erdos_gallai_graphical_sequence']
pub fn erdos_gallai_graphical_sequence(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length == 0 || length > max_parseable_length { return -1 }
		count_value := input[0]
		if count_value < 0 || count_value > max_vertices { return -1 }
		n := int(count_value)
		if length != usize(n + 1) { return -1 }

		mut degrees := []i64{len: n, init: 0}
		mut degree_sum := i64(0)
		for index in 0 .. n {
			degree := input[index + 1]
			if degree < 0 || degree >= count_value { return -1 }
			degrees[index] = degree
			degree_sum += degree
		}
		if n == 0 { return 1 }
		if degree_sum % 2 != 0 { return 0 }

		degrees.sort(a > b)
		mut prefix := [257]i64{}
		for index in 0 .. n {
			prefix[index + 1] = prefix[index] + degrees[index]
		}

		for k in 1 .. n + 1 {
			mut low := k
			mut high := n
			for low < high {
				middle := low + (high - low) / 2
				if degrees[middle] >= i64(k) {
					low = middle + 1
				} else {
					high = middle
				}
			}
			boundary := low
			k_value := i64(k)
			right_side := k_value * (k_value - 1) +
				k_value * i64(boundary - k) + prefix[n] - prefix[boundary]
			if prefix[k] > right_side { return 0 }
		}
		return 1
	}
}
