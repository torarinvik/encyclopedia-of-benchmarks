package online_temporary_task_load_balancing

import "core:c"

MAX_MACHINES :: 8
MAX_TASKS :: 32
MAX_PARSEABLE_WORDS :: 99

event_less :: proc(left, right: int, finish: [MAX_TASKS]i64) -> bool {
	if finish[left] != finish[right] do return finish[left] < finish[right]
	return left < right
}

heap_push :: proc(heap: ^[MAX_TASKS]int, size: ^int, task: int, finish: [MAX_TASKS]i64) {
	position := size^
	size^ += 1
	for position > 0 {
		parent := (position - 1) / 2
		if !event_less(task, heap[parent], finish) do break
		heap[position] = heap[parent]
		position = parent
	}
	heap[position] = task
}

heap_pop :: proc(heap: ^[MAX_TASKS]int, size: ^int, finish: [MAX_TASKS]i64) -> int {
	minimum := heap[0]
	size^ -= 1
	if size^ == 0 do return minimum
	replacement := heap[size^]
	position := 0
	for {
		left := 2 * position + 1
		if left >= size^ do break
		right := left + 1
		child := left
		if right < size^ && event_less(heap[right], heap[left], finish) do child = right
		if !event_less(heap[child], replacement, finish) do break
		heap[position] = heap[child]
		position = child
	}
	heap[position] = replacement
	return minimum
}

@(export)
online_temporary_task_load_balancing :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_WORDS do return -1
	if input[0] < 1 || input[0] > MAX_MACHINES || input[1] < 0 || input[1] > MAX_TASKS do return -1
	machine_count := int(input[0])
	task_count := int(input[1])
	if length != c.size_t(2 + 3 * task_count) do return -1

	var arrivals: [MAX_TASKS]i64
	var weights: [MAX_TASKS]i64
	var finish: [MAX_TASKS]i64
	var assigned: [MAX_TASKS]int
	var loads: [MAX_MACHINES]i64
	var heap: [MAX_TASKS]int
	heap_size := 0
	var staged: [MAX_TASKS + 1]i64
	previous_arrival: i64 = -1
	for task := 0; task < task_count; task += 1 {
		at := input[2 + 3 * task]
		amount := input[3 + 3 * task]
		duration := input[4 + 3 * task]
		if at < 0 || at > 1000 || at < previous_arrival || amount < 1 || amount > 1000 ||
			duration < 1 || duration > 1000 || at + duration > 2000 do return -1
		arrivals[task] = at
		weights[task] = amount
		finish[task] = at + duration
		previous_arrival = at
	}

	peak: i64 = 0
	for task := 0; task < task_count; task += 1 {
		for heap_size > 0 && finish[heap[0]] <= arrivals[task] {
			expired := heap_pop(&heap, &heap_size, finish)
			loads[assigned[expired]] -= weights[expired]
		}
		machine := 0
		for candidate := 1; candidate < machine_count; candidate += 1 {
			if loads[candidate] < loads[machine] do machine = candidate
		}
		assigned[task] = machine
		loads[machine] += weights[task]
		if loads[machine] > peak do peak = loads[machine]
		heap_push(&heap, &heap_size, task, finish)
	}
	staged[0] = peak
	for task := 0; task < task_count; task += 1 do staged[task + 1] = i64(assigned[task])
	output_words := task_count + 1
	output_bytes := 8 * output_words
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for word := 0; word < output_words; word += 1 {
		bits := u64(staged[word])
		for byte := 0; byte < 8; byte += 1 do output[8 * word + byte] = u8((bits >> u64(8 * byte)) & 255)
	}
	return i64(output_bytes)
}
