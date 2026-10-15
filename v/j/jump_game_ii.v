module jump_game_ii

const max_length = 1024

// Breadth-first search over forward-reachable indices.
@[export: 'jump_game_ii']
pub fn jump_game_ii(values &i64, length usize) i64 {
	if length == 0 || length > max_length { return -1 }
	unsafe {
		for index in 0 .. length {
			if values[index] < 0 || values[index] > i64(length) { return -1 }
		}
		if length == 1 { return 0 }
		mut queue := []usize{len: max_length, init: usize(0)}
		mut distance := []usize{len: max_length, init: usize(0)}
		mut visited := []bool{len: max_length, init: false}
		mut head := usize(0)
		mut tail := usize(1)
		queue[0] = 0
		visited[0] = true
		for head < tail {
			cell := queue[head]
			head++
			farthest := cell + usize(values[cell])
			if farthest >= length - 1 { return i64(distance[cell] + 1) }
			for next := cell + 1; next <= farthest; next++ {
				if !visited[next] {
					visited[next] = true
					distance[next] = distance[cell] + 1
					queue[tail] = next
					tail++
				}
			}
		}
		return -1
	}
}
