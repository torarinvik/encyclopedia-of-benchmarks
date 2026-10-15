module keys_and_rooms

// Return whether every room is reachable from room zero.
@[export: 'keys_and_rooms']
pub fn keys_and_rooms(values &i64, length usize) i64 {
	if length < 3 || length > 100001 { return -1 }
	unsafe {
		if values[0] < 2 || values[0] > 1000 { return -1 }
		n := int(values[0])
		mut starts := [1000]int{}
		mut degrees := [1000]int{}
		mut cursor := 1
		for room in 0 .. n {
			if cursor >= int(length) { return -1 }
			count_value := values[cursor]
			cursor++
			if count_value < 0 || count_value > i64(n) { return -1 }
			degree := int(count_value)
			if degree > int(length) - cursor { return -1 }
			starts[room] = cursor
			degrees[room] = degree
			for edge in 0 .. degree {
				key := values[cursor + edge]
				if key < 0 || key >= i64(n) { return -1 }
			}
			cursor += degree
		}
		if cursor != int(length) { return -1 }

		mut visited := [1000]bool{init: false}
		mut stack := [1000]int{}
		stack[0] = 0
		visited[0] = true
		mut stack_size := 1
		mut reached := 0
		for stack_size > 0 {
			stack_size--
			room := stack[stack_size]
			reached++
			for edge in 0 .. degrees[room] {
				key := int(values[starts[room] + edge])
				if !visited[key] {
					visited[key] = true
					stack[stack_size] = key
					stack_size++
				}
			}
		}
		if reached == n { return 1 }
		return 0
	}
}
