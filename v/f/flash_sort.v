module flash_sort

// Bounded Flash Sort followed by the source's insertion-sort finishing pass.
const max_length = 64

fn valid_length(length int) bool { return length <= 1 || (length >= 3 && length <= max_length) }
fn class_of(value i64, minimum i64, range i64, classes int) int {
	return int((i64(classes - 1) * (value - minimum)) / range)
}
fn flash_sort_values(mut values [64]i64, length int) bool {
	if length <= 1 { return true }
	mut minimum, mut maximum := values[0], values[0]
	for index in 1 .. length {
		if values[index] < minimum { minimum = values[index] }
		if values[index] > maximum { maximum = values[index] }
	}
	if minimum == maximum { return true }
	range := maximum - minimum
	mut classes := (9 * length) / 20
	if classes < 1 { classes = 1 }
	mut class_ends := [64]int{}
	for index in 0 .. length { class_ends[class_of(values[index], minimum, range, classes)]++ }
	for index in 1 .. classes { class_ends[index] += class_ends[index - 1] }
	mut moves, mut j, mut k := 0, 0, classes - 1
	for moves < length - 1 {
		for j > class_ends[k] - 1 {
			j++
			if j >= length { return false }
			k = class_of(values[j], minimum, range, classes)
		}
		mut flash := values[j]
		for j != class_ends[k] {
			k = class_of(flash, minimum, range, classes)
			class_ends[k]--
			target := class_ends[k]
			hold := values[target]
			values[target] = flash
			flash = hold
			moves++
		}
	}
	for index in 1 .. length {
		key := values[index]
		mut cursor := index
		for cursor > 0 && values[cursor - 1] > key {
			values[cursor] = values[cursor - 1]
			cursor--
		}
		values[cursor] = key
	}
	return true
}

@[export: 'flash_sort']
pub fn flash_sort(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > 65 { return -1 }
	if !valid_length(int(length)) || (length != 0 && unsafe { input == nil }) { return -1 }
	mut values := [64]i64{}
	for index in 0 .. int(length) {
		value := unsafe { input[index] }
		if value < -1000000 || value > 1000000 { return -1 }
		values[index] = value
	}
	output_bytes := int(length) * 4
	if output_capacity < usize(output_bytes) || (output_bytes != 0 && unsafe { output == nil }) { return -2 }
	if !flash_sort_values(mut values, int(length)) { return -1 }
	for index in 0 .. int(length) {
		bits := u32(i32(values[index]))
		for byte in 0 .. 4 { unsafe { output[index * 4 + byte] = u8((bits >> (8 * byte)) & 255) } }
	}
	return i64(output_bytes)
}
