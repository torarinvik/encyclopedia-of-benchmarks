package assignment_using_bitmask

import "core:c"

MAX_PEOPLE :: 10
MAX_TASKS :: 10
MAX_STATES :: 4096

@(export)
assignment_using_bitmask :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length < 2 do return -1
	people := input[0]
	tasks := input[1]
	if people < 0 || people > MAX_PEOPLE || tasks < 0 || tasks > MAX_TASKS || length != c.size_t(2 + people) do return -1
	valid_tasks := (i64(1) << u32(tasks)) - 1
	for person := 0; person < int(people); person += 1 {
		if input[person + 2] < 0 || input[person + 2] > valid_tasks do return -1
	}

	states := 1 << u32(people)
	ways: [MAX_STATES]i64
	next: [MAX_STATES]i64
	for mask := 0; mask < states; mask += 1 { ways[mask] = 0 }
	ways[0] = 1
	for task := i64(0); task < tasks; task += 1 {
		for mask := 0; mask < states; mask += 1 { next[mask] = 0 }
		for mask := 0; mask < states; mask += 1 {
			count := ways[mask]
			if count == 0 do continue
			next[mask] += count
			for person := 0; person < int(people); person += 1 {
				bit := 1 << u32(person)
				if (mask & bit) == 0 && (input[person + 2] & (i64(1) << u32(task))) != 0 {
					next[mask | bit] += count
				}
			}
		}
		ways = next
	}
	return ways[states - 1]
}
