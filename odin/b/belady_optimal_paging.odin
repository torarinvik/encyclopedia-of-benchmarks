package belady_optimal_paging

import "core:c"

MAX_CAPACITY :: 8
MAX_REQUESTS :: 64
PAGE_COUNT :: 16
MAX_INPUT_LENGTH :: 67
CHECKSUM_RADIX :: i64(33281)

@(export)
belady_optimal_paging :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	capacity_value, count_value := input[0], input[1]
	if capacity_value < 1 || capacity_value > MAX_CAPACITY || count_value < 0 || count_value > MAX_REQUESTS do return -1
	if length != c.size_t(2 + count_value) do return -1
	capacity, count := int(capacity_value), int(count_value)
	requests: [MAX_REQUESTS]int = {}
	for time := 0; time < count; time += 1 {
		if input[2+time] < 0 || input[2+time] >= PAGE_COUNT do return -1
		requests[time] = int(input[2+time])
	}
	next_after: [MAX_REQUESTS*PAGE_COUNT]int = {}
	next_position: [PAGE_COUNT]int = {}
	for page := 0; page < PAGE_COUNT; page += 1 { next_position[page] = count }
	for time := count; time > 0; time -= 1 {
		index := time - 1
		for page := 0; page < PAGE_COUNT; page += 1 { next_after[index*PAGE_COUNT+page] = next_position[page] }
		next_position[requests[index]] = index
	}

	resident: [PAGE_COUNT]bool = {}
	resident_count := 0
	misses, eviction_checksum := i64(0), i64(0)
	for time := 0; time < count; time += 1 {
		requested := requests[time]
		if resident[requested] do continue
		misses += 1
		if resident_count == capacity {
			victim, farthest := -1, -1
			for page := 0; page < PAGE_COUNT; page += 1 {
				if !resident[page] do continue
				following := next_after[time*PAGE_COUNT+page]
				if following > farthest { victim = page; farthest = following }
			}
			resident[victim] = false
			resident_count -= 1
			eviction_checksum += i64((time + 1) * (victim + 1))
		}
		resident[requested] = true
		resident_count += 1
	}
	return misses*CHECKSUM_RADIX + eviction_checksum
}
