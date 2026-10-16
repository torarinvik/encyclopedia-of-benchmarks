module minimum_sum_partition

const max_valid_input_length = 64
const max_total_sum = 4096

@[export: 'minimum_sum_partition']
pub fn minimum_sum_partition(input &i64, length usize) i64 {
	if length > max_valid_input_length || (input == nil && length > 0) { return -1 }
	unsafe {
		mut total := i64(0)
		for index in 0 .. int(length) {
			value := input[index]
			if value < 0 || value > i64(max_total_sum) || total > i64(max_total_sum) - value { return -1 }
			total += value
		}

		target := int(total / 2)
		mut reachable := []bool{len: max_total_sum / 2 + 1, init: false}
		reachable[0] = true
		mut closest := 0
		for index in 0 .. int(length) {
			value := int(input[index])
			mut sum := target
			for sum > 0 {
				if value <= sum && reachable[sum - value] { reachable[sum] = true }
				if reachable[sum] && sum > closest { closest = sum }
				sum--
			}
		}
		return total - 2 * i64(closest)
	}
}
