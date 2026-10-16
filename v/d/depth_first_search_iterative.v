module depth_first_search_iterative
const max_vertices = 64
const max_edges = 256
const max_input_length = 518
@[export: 'depth_first_search_iterative']
pub fn depth_first_search_iterative(input &i64, length usize) i64 {
	unsafe {
		if isnil(input) || length < 4 || length > max_input_length { return -1 }
		nv := input[0]
		mv := input[1]
		source := input[2]
		target := input[3]
		if nv < 1 || nv > max_vertices || mv < 0 || mv > max_edges || source < 0 || source >= nv { return -1 }
		m := int(mv)
		if length != usize(4 + 2 * m) { return -1 }
		for edge in 0 .. m {
			left := input[4 + 2 * edge]
			right := input[5 + 2 * edge]
			if left < 0 || left >= nv || right < 0 || right >= nv { return -1 }
		}
		mut visited := [max_vertices]bool{}
		mut pending := [max_vertices]int{}
		mut top := 1
		pending[0] = int(source)
		visited[pending[0]] = true
		for top > 0 {
			top -= 1
			current := pending[top]
			if i64(current) == target { return 1 }
			for edge in 0 .. m {
				left := input[4 + 2 * edge]
				right := input[5 + 2 * edge]
				mut neighbor := i64(-1)
				if left == i64(current) { neighbor = right } else if right == i64(current) { neighbor = left }
				if neighbor >= 0 {
					index := int(neighbor)
					if !visited[index] {
						visited[index] = true
						pending[top] = index
						top += 1
					}
				}
			}
		}
		return 0
	}
}
