import math

const max_count = 64
const heap_capacity = 32
const value_limit = i64(1_000_000)

fn heap_push(mut heap [32]i64, mut size int, is_max bool, value i64) {
	mut index := size
	size++
	heap[index] = value
	for index > 0 {
		parent := (index - 1) / 2
		ordered := if is_max { heap[parent] >= heap[index] } else { heap[parent] <= heap[index] }
		if ordered { break }
		heap[parent], heap[index] = heap[index], heap[parent]
		index = parent
	}
}

fn heap_pop(mut heap [32]i64, mut size int, is_max bool) i64 {
	result := heap[0]
	size--
	heap[0] = heap[size]
	mut index := 0
	for {
		left := 2 * index + 1
		right := left + 1
		mut best := index
		if left < size && (if is_max { heap[left] > heap[best] } else { heap[left] < heap[best] }) { best = left }
		if right < size && (if is_max { heap[right] > heap[best] } else { heap[right] < heap[best] }) { best = right }
		if best == index { break }
		heap[index], heap[best] = heap[best], heap[index]
		index = best
	}
	return result
}

fn write_f64_le(mut output &u8, position int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[position + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'median_finder']
pub fn median_finder(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_count + 1 { return -1 }
		count_value := input[0]
		if count_value < 1 || count_value > max_count || int(length) != int(count_value) + 1 { return -1 }
		count := int(count_value)
		for index in 0 .. count {
			if input[index + 1] < -value_limit || input[index + 1] > value_limit { return -1 }
		}
		required := usize(count * 8)
		if output == nil || output_capacity < required { return -2 }

		mut lower := [heap_capacity]i64{}
		mut upper := [heap_capacity]i64{}
		mut lower_size := 0
		mut upper_size := 0
		for index in 0 .. count {
			value := input[index + 1]
			if lower_size == heap_capacity && lower_size > upper_size && value <= lower[0] {
				heap_push(mut upper, mut upper_size, false, heap_pop(mut lower, mut lower_size, true))
				heap_push(mut lower, mut lower_size, true, value)
			} else {
				if lower_size == 0 || value <= lower[0] { heap_push(mut lower, mut lower_size, true, value) }
				else { heap_push(mut upper, mut upper_size, false, value) }
				if lower_size > upper_size + 1 {
					heap_push(mut upper, mut upper_size, false, heap_pop(mut lower, mut lower_size, true))
				} else if upper_size > lower_size {
					heap_push(mut lower, mut lower_size, true, heap_pop(mut upper, mut upper_size, false))
				}
			}
			median := if lower_size == upper_size {
				(f64(lower[0]) + f64(upper[0])) / 2.0
			} else {
				f64(lower[0])
			}
			write_f64_le(mut output, index * 8, median)
		}
		return i64(required)
	}
}
