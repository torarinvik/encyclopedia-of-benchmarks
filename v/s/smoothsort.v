module smoothsort

const max_count = 64
const max_input_length = 66

fn sift(mut values [64]i64, root_arg int, order_arg int, leonardo [16]int) {
	mut root := root_arg; mut order := order_arg
	for order > 1 {
		right := root - 1; left := root - 1 - leonardo[order - 2]
		if !(values[left] < values[right]) && values[root] < values[left] { values[root], values[left] = values[left], values[root]; root = left; order-- }
		else if values[left] < values[right] && values[root] < values[right] { values[root], values[right] = values[right], values[root]; root = right; order -= 2 }
		else { break }
	}
}
fn trinkle(mut values [64]i64, position_arg int, mut orders [64]int, index_arg int, leonardo [16]int) {
	mut position := position_arg; mut index := index_arg
	for index > 0 {
		previous := position - leonardo[orders[index]]
		if !(values[position] < values[previous]) { break }
		if orders[index] > 1 {
			right := position - 1; left := position - 1 - leonardo[orders[index] - 2]
			if !(values[right] < values[previous]) || !(values[left] < values[previous]) { break }
		}
		values[position], values[previous] = values[previous], values[position]; position = previous; index--
	}
	sift(mut values, position, orders[index], leonardo)
}
fn smooth_sort(mut values [64]i64, count int) {
	if count < 2 { return }
	mut leonardo := [16]int{}; leonardo[0] = 1; leonardo[1] = 1
	for i in 2 .. 16 { leonardo[i] = leonardo[i - 1] + leonardo[i - 2] + 1 }
	mut orders := [64]int{}; mut heap_count := 0
	for position in 0 .. count {
		if heap_count >= 2 && orders[heap_count - 2] == orders[heap_count - 1] + 1 { heap_count--; orders[heap_count - 1]++ }
		else if heap_count > 0 && orders[heap_count - 1] == 1 { orders[heap_count] = 0; heap_count++ }
		else { orders[heap_count] = 1; heap_count++ }
		trinkle(mut values, position, mut orders, heap_count - 1, leonardo)
	}
	for position := count - 1; position >= 0; position-- {
		heap_count--; order := orders[heap_count]
		if order > 1 {
			right_order := order - 2; left_order := order - 1
			right_position := position - 1; left_position := position - 1 - leonardo[right_order]
			orders[heap_count] = left_order; heap_count++; trinkle(mut values, left_position, mut orders, heap_count - 1, leonardo)
			orders[heap_count] = right_order; heap_count++; trinkle(mut values, right_position, mut orders, heap_count - 1, leonardo)
		}
	}
}
fn store_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) } }
}

@[export: 'smoothsort']
pub fn smoothsort(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > usize(max_input_length) { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > i64(max_count) { return -1 }
		count := int(input[0])
		if length != usize(1 + count) || length > usize(max_count + 1) { return -1 }
		mut values := [64]i64{}
		for i in 0 .. count { values[i] = input[i + 1] }
		smooth_sort(mut values, count)
		bytes := count * 8
		if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
		for i in 0 .. count { store_i64(mut output, i * 8, values[i]) }
		return i64(bytes)
	}
}
