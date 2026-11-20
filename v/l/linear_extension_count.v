module linear_extension_count

const max_n = 12
const max_length = 14
const max_states = 4096

@[export: 'linear_extension_count']
pub fn linear_extension_count(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_length { return -1 }
		if input[0] < 0 || input[0] > max_n { return -1 }
		n := int(input[0])
		if length != usize(n+1) { return -1 }
		full := (1 << n)-1
		mut predecessor := [max_n]int{}
		for vertex in 0 .. n {
			if input[1+vertex] < 0 || input[1+vertex] > i64(full) { return -1 }
			predecessor[vertex] = int(input[1+vertex])
		}
		mut ways := [max_states]i64{}
		ways[0] = 1
		for prefix in 0 .. full+1 {
			count := ways[prefix]
			if count == 0 { continue }
			for vertex in 0 .. n {
				bit := 1 << vertex
				if (prefix & bit) == 0 && (predecessor[vertex] & prefix) == predecessor[vertex] {
					ways[prefix | bit] += count
				}
			}
		}
		return ways[full]
	}
}
