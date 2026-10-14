module heap_sort_2

fn sift_up(mut values &i64, index_value usize) {
	mut index := index_value
	for index > 0 {
		parent := (index - 1) / 2
		if unsafe { values[parent] >= values[index] } { break }
		temporary := unsafe { values[parent] }
		unsafe { values[parent] = values[index] }
		unsafe { values[index] = temporary }
		index = parent
	}
}

fn sift_down(mut values &i64, size usize) {
	mut root := usize(0)
	for root < size / 2 {
		left := root * 2 + 1
		mut largest := left
		right := left + 1
		if right < size && unsafe { values[right] > values[left] } { largest = right }
		if unsafe { values[root] >= values[largest] } { break }
		temporary := unsafe { values[root] }
		unsafe { values[root] = values[largest] }
		unsafe { values[largest] = temporary }
		root = largest
	}
}

@[export: 'heap_sort_2']
pub fn heap_sort_2(mut values &i64, length usize) {
	if length > 1024 { return }
	for index in usize(0) .. length { sift_up(mut values, index) }
	mut size := length
	for size > 1 {
		temporary := unsafe { values[0] }
		unsafe { values[0] = values[size - 1] }
		unsafe { values[size - 1] = temporary }
		size--
		sift_down(mut values, size)
	}
}
