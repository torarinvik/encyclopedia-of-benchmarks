module array_pair_sum

const max_length = 4096

// Sort signed 32-bit values and sum the first of every adjacent pair.
@[export: 'array_pair_sum']
pub fn array_pair_sum(input &i64, length usize) i64 {
	if length > max_length || length % 2 != 0 { return -1 }
	mut values := [max_length]i64{init: 0}
	for index in 0 .. length {
		value := unsafe { input[index] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[index] = value
	}
	mut start := length / 2
	for start > 0 {
		start--
		mut root := start
		for root * 2 + 1 < length {
			mut child := root * 2 + 1
			if child + 1 < length && values[child] < values[child + 1] { child++ }
			if values[root] >= values[child] { break }
			temporary := values[root]
			values[root] = values[child]
			values[child] = temporary
			root = child
		}
	}
	mut ending := length
	for ending > 1 {
		ending--
		mut temporary := values[0]
		values[0] = values[ending]
		values[ending] = temporary
		mut root := usize(0)
		for root * 2 + 1 < ending {
			mut child := root * 2 + 1
			if child + 1 < ending && values[child] < values[child + 1] { child++ }
			if values[root] >= values[child] { break }
			temporary = values[root]
			values[root] = values[child]
			values[child] = temporary
			root = child
		}
	}
	mut total := i64(0)
	mut index := usize(0)
	for index < length {
		total += values[index]
		index += 2
	}
	return total
}
