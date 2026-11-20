package sieve_of_pritchard

import "core:c"

MAX_LIMIT :: i64(1024)
LINK_COUNT :: 1026

@(export)
sieve_of_pritchard :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(2) do return -1
	if length != 1 || input[0] < 2 || input[0] > MAX_LIMIT do return -1

	limit := i32(input[0])
	sentinel := limit + 1
	next_node: [LINK_COUNT]i32 = {}
	previous: [LINK_COUNT]i32 = {}
	next_node[1] = sentinel
	next_node[int(sentinel)] = sentinel
	previous[int(sentinel)] = 1
	wheel_length := i32(2)
	prime := i32(3)
	prime_count := i64(1)

	for prime*prime <= limit {
		if wheel_length < limit {
			product := prime * wheel_length
			target := product
			if target > limit do target = limit
			wheel_value := i32(1)
			candidate := wheel_length + 1
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

		wheel_value := prime
		for prime*wheel_value <= wheel_length {
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
		prime_count += 1
		prime = next_node[1]
	}

	if wheel_length < limit {
		wheel_value := i32(1)
		candidate := wheel_length + 1
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

	remaining := i64(0)
	value := next_node[1]
	for value != sentinel {
		remaining += 1
		value = next_node[int(value)]
	}
	return prime_count + remaining
}
