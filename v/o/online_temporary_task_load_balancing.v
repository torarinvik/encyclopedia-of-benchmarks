module online_temporary_task_load_balancing

const max_machines = 8
const max_tasks = 32
const max_parseable_words = 99

fn event_less(left int, right int, finish []i64) bool {
	if finish[left] != finish[right] {
		return finish[left] < finish[right]
	}
	return left < right
}

fn heap_push(mut heap []int, mut size int, task int, finish []i64) {
	mut position := size
	size++
	for position > 0 {
		parent := (position - 1) / 2
		if !event_less(task, heap[parent], finish) {
			break
		}
		heap[position] = heap[parent]
		position = parent
	}
	heap[position] = task
}

fn heap_pop(mut heap []int, mut size int, finish []i64) int {
	minimum := heap[0]
	size--
	if size == 0 {
		return minimum
	}
	replacement := heap[size]
	mut position := 0
	for {
		left := 2 * position + 1
		if left >= size {
			break
		}
		right := left + 1
		mut child := left
		if right < size && event_less(heap[right], heap[left], finish) {
			child = right
		}
		if !event_less(heap[child], replacement, finish) {
			break
		}
		heap[position] = heap[child]
		position = child
	}
	heap[position] = replacement
	return minimum
}

@[export: 'online_temporary_task_load_balancing']
pub fn online_temporary_task_load_balancing(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 2 || length > max_parseable_words || unsafe { input == nil } {
		return -1
	}
	unsafe {
		if input[0] < 1 || input[0] > max_machines || input[1] < 0 || input[1] > max_tasks {
			return -1
		}
		machine_count := int(input[0])
		task_count := int(input[1])
		if length != usize(2 + 3 * task_count) {
			return -1
		}
		mut arrivals := []i64{len: max_tasks, init: 0}
		mut weights := []i64{len: max_tasks, init: 0}
		mut finish := []i64{len: max_tasks, init: 0}
		mut assigned := []int{len: max_tasks, init: 0}
		mut loads := []i64{len: max_machines, init: 0}
		mut heap := []int{len: max_tasks, init: 0}
		mut heap_size := 0
		mut staged := []i64{len: max_tasks + 1, init: 0}
		mut previous_arrival := i64(-1)
		for task in 0 .. task_count {
			at := input[2 + 3 * task]
			amount := input[3 + 3 * task]
			duration := input[4 + 3 * task]
			if at < 0 || at > 1000 || at < previous_arrival || amount < 1 || amount > 1000 ||
				duration < 1 || duration > 1000 || at + duration > 2000 {
				return -1
			}
			arrivals[task] = at
			weights[task] = amount
			finish[task] = at + duration
			previous_arrival = at
		}
		mut peak := i64(0)
		for task in 0 .. task_count {
			for heap_size > 0 && finish[heap[0]] <= arrivals[task] {
				expired := heap_pop(mut heap, mut heap_size, finish)
				loads[assigned[expired]] -= weights[expired]
			}
			mut machine := 0
			for candidate in 1 .. machine_count {
				if loads[candidate] < loads[machine] {
					machine = candidate
				}
			}
			assigned[task] = machine
			loads[machine] += weights[task]
			if loads[machine] > peak {
				peak = loads[machine]
			}
			heap_push(mut heap, mut heap_size, task, finish)
		}
		staged[0] = peak
		for task in 0 .. task_count {
			staged[task + 1] = i64(assigned[task])
		}
		output_words := task_count + 1
		output_bytes := 8 * output_words
		if output == nil || capacity < usize(output_bytes) {
			return -2
		}
		for word in 0 .. output_words {
			bits := u64(staged[word])
			for byte in 0 .. 8 {
				output[8 * word + byte] = u8((bits >> (8 * byte)) & 255)
			}
		}
		return i64(output_bytes)
	}
}
