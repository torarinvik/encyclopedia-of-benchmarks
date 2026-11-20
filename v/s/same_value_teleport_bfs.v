module same_value_teleport_bfs

@[export: 'same_value_teleport_bfs']
pub fn same_value_teleport_bfs(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 65 { return -2 }
	first_value := unsafe { input[0] }
	if first_value < 1 || first_value > 64 || length != usize(first_value + 1) { return -2 }
	n := int(first_value)
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < -64 || value > 64 { return -2 }
	}
	if n == 1 { return 0 }

	mut first := [129]int{}
	mut next := [64]int{}
	mut queue := [64]int{}
	mut distance := [64]int{}
	for i in 0 .. 129 { first[i] = -1 }
	for i in 0 .. n {
		slot := int(unsafe { input[i + 1] } + 64)
		next[i] = first[slot]
		first[slot] = i
		distance[i] = -1
	}
	mut front := 0
	mut back := 1
	queue[0] = 0
	distance[0] = 0
	for front < back {
		index := queue[front]
		front++
		if index == n - 1 { return i64(distance[index]) }
		if index > 0 && distance[index - 1] < 0 {
			distance[index - 1] = distance[index] + 1
			queue[back] = index - 1
			back++
		}
		if index + 1 < n && distance[index + 1] < 0 {
			distance[index + 1] = distance[index] + 1
			queue[back] = index + 1
			back++
		}
		slot := int(unsafe { input[index + 1] } + 64)
		mut member := first[slot]
		if member >= 0 {
			first[slot] = -1
			for member >= 0 {
				if distance[member] < 0 {
					distance[member] = distance[index] + 1
					queue[back] = member
					back++
				}
				member = next[member]
			}
		}
	}
	return i64(distance[n - 1])
}
