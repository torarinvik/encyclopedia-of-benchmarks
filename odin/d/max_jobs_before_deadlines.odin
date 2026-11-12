package max_jobs_before_deadlines

import "core:c"

MAX_JOBS :: 12

Job :: struct {
	deadline: i64,
	duration: i64,
	id: int,
}

before :: proc "contextless" (left_duration: i64, left_id: int,
		right_duration: i64, right_id: int) -> bool {
	return left_duration < right_duration ||
		(left_duration == right_duration && left_id < right_id)
}

heap_push :: proc "contextless" (durations: [^]i64, ids: [^]int,
		size: ^int, duration: i64, id: int) {
	index := size^
	size^ += 1
	for index > 0 {
		parent := (index - 1) / 2
		if !before(duration, id, durations[parent], ids[parent]) do break
		durations[index] = durations[parent]
		ids[index] = ids[parent]
		index = parent
	}
	durations[index] = duration
	ids[index] = id
}

heap_pop :: proc "contextless" (durations: [^]i64, ids: [^]int,
		size: ^int) -> (i64, int) {
	result := durations[0], ids[0]
	size^ -= 1
	if size^ == 0 do return result
	last_duration := durations[size^]
	last_id := ids[size^]
	index := 0
	for 2 * index + 1 < size^ {
		child := 2 * index + 1
		if child + 1 < size^ && before(durations[child + 1], ids[child + 1], durations[child], ids[child]) {
			child += 1
		}
		if !before(durations[child], ids[child], last_duration, last_id) do break
		durations[index] = durations[child]
		ids[index] = ids[child]
		index = child
	}
	durations[index] = last_duration
	ids[index] = last_id
	return result
}

@(export)
max_jobs_before_deadlines :: proc "contextless" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 25 do return -1
	count_value := input[0]
	if count_value < 0 || count_value > MAX_JOBS || int(length) != 1 + 2 * int(count_value) do return -1
	count := int(count_value)
	jobs: [MAX_JOBS]Job
	for i := 0; i < count; i += 1 {
		deadline, duration := input[1 + 2 * i], input[2 + 2 * i]
		if deadline < 0 || deadline > 1000 || duration < 1 || duration > 1000 do return -1
		jobs[i] = Job{deadline, duration, i}
	}
	for i := 1; i < count; i += 1 {
		item := jobs[i]
		position := i
		for position > 0 && jobs[position - 1].deadline > item.deadline {
			jobs[position] = jobs[position - 1]
			position -= 1
		}
		jobs[position] = item
	}
	heap_durations: [MAX_JOBS]i64 = {}
	heap_ids: [MAX_JOBS]int = {}
	heap_size := 0
	completed := i64(0)
	end := count
	for end > 0 {
		end -= 1
		heap_push(&heap_durations[0], &heap_ids[0], &heap_size, jobs[end].duration, jobs[end].id)
		lower := i64(0)
		if end > 0 do lower = jobs[end - 1].deadline
		interval := jobs[end].deadline - lower
		for interval > 0 && heap_size > 0 {
			remaining, id := heap_pop(&heap_durations[0], &heap_ids[0], &heap_size)
			if remaining <= interval {
				interval -= remaining
				completed += 1
			} else {
				heap_push(&heap_durations[0], &heap_ids[0], &heap_size, remaining - interval, id)
				interval = 0
			}
		}
	}
	return completed
}
