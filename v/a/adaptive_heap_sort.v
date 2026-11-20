module adaptive_heap_sort

const max_values = 1024

fn node_less(values &i64, left usize, right usize) bool {
	return unsafe { values[left] < values[right] || (values[left] == values[right] && left < right) }
}

fn push_candidate(values &i64, mut heap &usize, mut heap_length &usize, node usize) {
	mut position := heap_length
	heap_length++
	unsafe { heap[position] = node }
	for position > 0 {
		parent := (position - 1) / 2
		if !node_less(values, unsafe { heap[position] }, unsafe { heap[parent] }) { break }
		unsafe {
			temporary := heap[position]
			heap[position] = heap[parent]
			heap[parent] = temporary
		}
		position = parent
	}
}

fn pop_candidate(values &i64, mut heap &usize, mut heap_length &usize) usize {
	minimum := unsafe { heap[0] }
	heap_length--
	if heap_length == 0 { return minimum }
	unsafe { heap[0] = heap[heap_length] }
	mut position := usize(0)
	for position < heap_length / 2 {
		mut child := position * 2 + 1
		if child + 1 < heap_length
			&& node_less(values, unsafe { heap[child + 1] }, unsafe { heap[child] }) {
			child++
		}
		if !node_less(values, unsafe { heap[child] }, unsafe { heap[position] }) { break }
		unsafe {
			temporary := heap[position]
			heap[position] = heap[child]
			heap[child] = temporary
		}
		position = child
	}
	return minimum
}

@[export: 'adaptive_heap_sort']
pub fn adaptive_heap_sort(mut values &i64, length usize) {
	if values == nil || length < 2 || length > max_values { return }
	mut left := [max_values]usize{}
	mut right := [max_values]usize{}
	mut construction_stack := [max_values]usize{}
	mut candidate_heap := [max_values]usize{}
	mut output := [max_values]i64{}

	mut stack_length := usize(0)
	for index in 0 .. length {
		left[index] = length
		right[index] = length
		mut last := length
		for stack_length > 0 && unsafe { values[construction_stack[stack_length - 1]] > values[index] } {
			stack_length--
			last = construction_stack[stack_length]
		}
		if stack_length > 0 { right[construction_stack[stack_length - 1]] = index }
		if last < length { left[index] = last }
		construction_stack[stack_length] = index
		stack_length++
	}

	mut heap_length := usize(0)
	push_candidate(values, mut candidate_heap[0], mut heap_length, construction_stack[0])
	for output_index in 0 .. length {
		node := pop_candidate(values, mut candidate_heap[0], mut heap_length)
		unsafe { output[output_index] = values[node] }
		if left[node] < length { push_candidate(values, mut candidate_heap[0], mut heap_length, left[node]) }
		if right[node] < length { push_candidate(values, mut candidate_heap[0], mut heap_length, right[node]) }
	}
	for index in 0 .. length {
		unsafe { values[index] = output[index] }
	}
}
