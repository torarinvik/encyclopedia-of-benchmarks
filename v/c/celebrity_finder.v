module celebrity_finder

@[export: 'celebrity_finder']
pub fn celebrity_finder(input &i64, length usize) i64 {
	if input == nil || length < 2 { return -2 }
	unsafe {
		if input[0] < 1 || input[0] > 64 { return -2 }
		n := int(input[0])
		if length != usize(1 + n * n) { return -2 }
		for i in 1 .. int(length) { if input[i] != 0 && input[i] != 1 { return -2 } }
		mut stack := []int{len: n}
		for i in 0 .. n { stack[i] = i }
		mut top := n
		for top > 1 {
			top--
			person1 := stack[top]
			top--
			person2 := stack[top]
			if input[1 + person1 * n + person2] == 1 { stack[top] = person2 } else { stack[top] = person1 }
			top++
		}
		candidate := stack[0]
		for i in 0 .. n {
			if i != candidate && (input[1 + candidate * n + i] == 1 || input[1 + i * n + candidate] == 0) { return -1 }
		}
		return i64(candidate)
	}
}
