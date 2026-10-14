module patience_sort

const max_input_length = 1024

fn node_less(keys &i64, left usize, right usize) bool {
	return unsafe { keys[left] < keys[right] || (keys[left] == keys[right] && left < right) }
}

fn sift_down(mut keys &i64, mut heap &usize, heap_length usize, start_root usize) {
	mut root := start_root
	for root < heap_length / 2 {
		mut child := root * 2 + 1
		if child + 1 < heap_length && node_less(keys, unsafe { heap[child + 1] }, unsafe { heap[child] }) {
			child++
		}
		if !node_less(keys, unsafe { heap[child] }, unsafe { heap[root] }) { break }
		unsafe {
			temporary := heap[root]
			heap[root] = heap[child]
			heap[child] = temporary
		}
		root = child
	}
}

@[export: 'patience_sort']
pub fn patience_sort(mut values &i64, length usize) {
	if length < 2 || length > max_input_length { return }
	mut keys := [max_input_length]i64{}
	mut pile_tops := [max_input_length]usize{}
	mut next_in_pile := [max_input_length]usize{}
	mut heap := [max_input_length]usize{}
	mut pile_count := usize(0)
	for index in 0 .. length {
		unsafe { keys[index] = values[index] }
		next_in_pile[index] = length
		mut low := usize(0)
		mut high := pile_count
		for low < high {
			middle := low + (high - low) / 2
			if keys[pile_tops[middle]] >= keys[index] { high = middle } else { low = middle + 1 }
		}
		if low == pile_count {
			pile_tops[pile_count] = index
			pile_count++
		} else {
			next_in_pile[index] = pile_tops[low]
			pile_tops[low] = index
		}
	}
	for pile in 0 .. pile_count { heap[pile] = pile_tops[pile] }
	mut heap_length := pile_count
	mut start := heap_length / 2
	for start > 0 {
		start--
		sift_down(mut keys[0], mut heap[0], heap_length, start)
	}
	mut output := usize(0)
	for heap_length > 0 {
		node := heap[0]
		unsafe { values[output] = keys[node] }
		output++
		successor := next_in_pile[node]
		if successor < length { heap[0] = successor }
		else {
			heap_length--
			if heap_length > 0 { heap[0] = heap[heap_length] }
		}
		if heap_length > 0 { sift_down(mut keys[0], mut heap[0], heap_length, 0) }
	}
}
