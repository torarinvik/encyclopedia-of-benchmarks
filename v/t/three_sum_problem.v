module three_sum_problem

const max_items = 257
const bytes_per_triplet = 12

fn sift_down(mut values &i64, root_start int, end_value int) {
	mut root := root_start
	for root < end_value / 2 {
		mut child := root * 2 + 1
		if child + 1 < end_value && unsafe { values[child] < values[child + 1] } { child++ }
		if unsafe { values[root] >= values[child] } { break }
		unsafe {
			temporary := values[root]
			values[root] = values[child]
			values[child] = temporary
		}
		root = child
	}
}

fn heap_sort(mut values &i64, length int) {
	mut start := length / 2
	for start > 0 {
		start--
		sift_down(mut values, start, length)
	}
	mut ending := length
	for ending > 1 {
		ending--
		unsafe {
			temporary := values[0]
			values[0] = values[ending]
			values[ending] = temporary
		}
		sift_down(mut values, 0, ending)
	}
}

fn store_i32_le(output &u8, offset int, value i64) {
	bits := u32(i32(value))
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

fn enumerate_triplets(values &i64, length int, target i64, output &u8, write_output bool) int {
	mut result_count := 0
	mut first := 0
	for first + 2 < length {
		if first > 0 && unsafe { values[first] } == unsafe { values[first - 1] } {
			first++
			continue
		}
		mut left := first + 1
		mut right := length - 1
		for left < right {
			sum := unsafe { values[first] } + unsafe { values[left] } + unsafe { values[right] }
			if sum < target {
				left++
			} else if sum > target {
				right--
			} else {
				if write_output {
					offset := result_count * bytes_per_triplet
					store_i32_le(output, offset, unsafe { values[first] })
					store_i32_le(output, offset + 4, unsafe { values[left] })
					store_i32_le(output, offset + 8, unsafe { values[right] })
				}
				result_count++
				left++
				right--
				for left < right && unsafe { values[left] } == unsafe { values[left - 1] } { left++ }
				for left < right && unsafe { values[right] } == unsafe { values[right + 1] } { right-- }
			}
		}
		first++
	}
	return result_count
}

// Return unique sorted target-sum triplets using sort-and-two-pointers.
@[export: 'three_sum_problem']
pub fn three_sum_problem(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 || length > 259 { return -1 }
	target := unsafe { input[0] }
	n := unsafe { input[1] }
	if target < -2147483648 || target > 2147483647 || n < 0 || n > 257 || length != usize(n + 2) { return -1 }
	mut values := [max_items]i64{init: 0}
	for index in 0 .. int(n) {
		value := unsafe { input[index + 2] }
		if value < -100000 || value > 100000 { return -1 }
		values[index] = value
	}
	heap_sort(mut values[0], int(n))
	maximum_bytes := if n < 2 { usize(0) } else { usize(n * (n - 1) / 2 * bytes_per_triplet) }
	if output_capacity < maximum_bytes {
		needed := usize(enumerate_triplets(values[0], int(n), target, output, false) * bytes_per_triplet)
		if output_capacity < needed { return -2 }
	}
	return i64(enumerate_triplets(values[0], int(n), target, output, true))
}
