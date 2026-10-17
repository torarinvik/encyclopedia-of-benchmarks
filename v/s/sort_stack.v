module sort_stack

const max_items = 64

fn insert_sorted(mut stack [max_items]i32, mut size int, value i32) {
	if size == 0 || value > stack[size - 1] {
		stack[size] = value
		size++
		return
	}
	size--
	top := stack[size]
	insert_sorted(mut stack, mut size, value)
	stack[size] = top
	size++
}

fn sort_recursively(mut stack [max_items]i32, mut size int) {
	if size == 0 { return }
	size--
	top := stack[size]
	sort_recursively(mut stack, mut size)
	insert_sorted(mut stack, mut size, top)
}

@[export: 'sort_stack']
pub fn sort_stack(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 65 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_items || length != usize(1 + input[0]) { return -1 }
		count := int(input[0])
		mut stack := [max_items]i32{}
		for i in 0 .. count {
			if input[i + 1] < -2147483648 || input[i + 1] > 2147483647 { return -1 }
			stack[i] = i32(input[i + 1])
		}
		mut size := count
		sort_recursively(mut stack, mut size)
		bytes := size * 4
		if output == nil || output_capacity < usize(bytes) { return -2 }
		for i in 0 .. size {
			bits := u32(stack[i])
			for b in 0 .. 4 { output[4 * i + b] = u8((bits >> (8 * b)) & u32(255)) }
		}
		return i64(bytes)
	}
}
