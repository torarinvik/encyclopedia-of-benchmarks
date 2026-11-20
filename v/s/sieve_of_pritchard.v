module main

const max_limit = i64(1024)
const link_count = 1026

@[export: 'sieve_of_pritchard']
pub fn sieve_of_pritchard(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 2 { return -1 }
		if length != 1 || input[0] < 2 || input[0] > max_limit { return -1 }
		limit := i32(input[0])
		sentinel := limit + 1
		mut next_node := [link_count]i32{init: 0}
		mut previous := [link_count]i32{init: 0}
		next_node[1] = sentinel
		next_node[int(sentinel)] = sentinel
		previous[int(sentinel)] = 1
		mut wheel_length := i32(2)
		mut prime := i32(3)
		mut prime_count := i64(1)

		for prime * prime <= limit {
			if wheel_length < limit {
				product := prime * wheel_length
				target := if product < limit { product } else { limit }
				mut wheel_value := i32(1)
				mut candidate := wheel_length + 1
				for candidate <= target {
					tail := previous[int(sentinel)]
					next_node[int(tail)] = candidate
					previous[int(candidate)] = tail
					next_node[int(candidate)] = sentinel
					previous[int(sentinel)] = candidate
					wheel_value = next_node[int(wheel_value)]
					candidate = wheel_length + wheel_value
				}
				wheel_length = target
			}

			mut wheel_value := prime
			for prime * wheel_value <= wheel_length {
				wheel_value = next_node[int(wheel_value)]
			}
			for wheel_value > 1 {
				wheel_value = previous[int(wheel_value)]
				removed := prime * wheel_value
				left := previous[int(removed)]
				right := next_node[int(removed)]
				next_node[int(left)] = right
				previous[int(right)] = left
			}
			prime_count++
			prime = next_node[1]
		}

		if wheel_length < limit {
			mut wheel_value := i32(1)
			mut candidate := wheel_length + 1
			for candidate <= limit {
				tail := previous[int(sentinel)]
				next_node[int(tail)] = candidate
				previous[int(candidate)] = tail
				next_node[int(candidate)] = sentinel
				previous[int(sentinel)] = candidate
				wheel_value = next_node[int(wheel_value)]
				candidate = wheel_length + wheel_value
			}
			wheel_length = limit
		}

		mut remaining := i64(0)
		mut value := next_node[1]
		for value != sentinel {
			remaining++
			value = next_node[int(value)]
		}
		return prime_count + remaining
	}
}
